<?php
namespace App\Services;
use App\Models\{CareNotification, DeviceToken, CaregiverLink, CaregiverPermission};
use Illuminate\Support\Facades\Http;
use Google\Auth\Credentials\ServiceAccountCredentials;
class NotificationService
{
    public function send(string $user, string $type, string $key): void
    {
        $n = CareNotification::firstOrNew(["dedupe_key" => $key]);
        if ($n->exists) {
            return;
        }
        $n->forceFill([
            "user_id" => $user,
            "notification_type" => $type,
            "title" => "Hopely Care",
            "body" => match ($type) {
                "emergency_support" => "Seseorang di Care Circle meminta Bantuan Cepat. Buka Hopely Care untuk melihat dan menanggapi.",
                "emergency_support_update" => "Status Bantuan Cepat telah diperbarui. Buka Hopely Care untuk melihat status terbaru.",
                "treatment_due" => "Waktu jadwal perjalananmu telah tiba. Buka Hopely Care untuk melihatnya.",
                "activity_reminder" => "Ada aktivitas dukungan yang kamu jadwalkan. Buka Hopely Care jika kamu ingin melakukannya.",
                "treatment_reminder" => "Ada jadwal perjalanan dalam 24 jam ke depan. Buka Hopely Care untuk melihatnya.",
                default => "Ada pengingat baru. Buka Hopely Care untuk melihatnya.",
            },
        ])->save();
        \Illuminate\Support\Facades\DB::afterCommit(fn() => $this->push($n, $user));
    }
    private function push(CareNotification $n, string $user): void
    {
        $file = config("services.firebase.credentials");
        $project = config("services.firebase.project_id");
        if (!$file || !$project || !is_readable($file)) {
            $n->forceFill(['push_status' => 'not_configured'])->save();
            return;
        }
        $n->forceFill([
            'push_attempts' => $n->push_attempts + 1,
            'push_attempted_at' => now(),
            'push_status' => 'sending',
        ])->save();
        try {
            $auth = new ServiceAccountCredentials(
                "https://www.googleapis.com/auth/firebase.messaging",
                json_decode(file_get_contents($file), true, 512, JSON_THROW_ON_ERROR),
            );
            $token = $auth->fetchAuthToken()["access_token"] ?? null;
            if (!$token) {
                $n->forceFill(['push_status' => 'failed'])->save();
                return;
            }
            $accepted = 0;
            $failed = 0;
            foreach (DeviceToken::where("user_id", $user)->get() as $d) {
                $r = Http::timeout(10)
                    ->withToken($token)
                    ->post(
                        "https://fcm.googleapis.com/v1/projects/" . $project . "/messages:send",
                        [
                            "message" => [
                                "token" => $d->token,
                                "notification" => ["title" => $n->title, "body" => $n->body],
                                "data" => ["notification_id" => $n->id],
                            ],
                        ],
                    );
                if ($r->successful()) {
                    $accepted++;
                } else {
                    $failed++;
                }
                if ($r->status() === 404) {
                    $d->delete();
                }
            }
            $n->forceFill([
                'push_status' => $accepted > 0 ? ($failed > 0 ? 'partial' : 'provider_accepted') : ($failed > 0 ? 'failed' : 'no_device'),
                'push_accepted_at' => $accepted > 0 ? now() : null,
            ])->save();
        } catch (\Throwable $e) {
            $n->forceFill(['push_status' => 'failed'])->save();
            /* Never include credentials or payload in application logs. In-app notification remains available. */
        }
    }
    public function retryPending(): void
    {
        CareNotification::whereIn('push_status', ['pending', 'failed', 'not_configured', 'no_device', 'sending'])
            ->where('push_attempts', '<', 5)
            ->where('created_at', '>=', now()->subDay())
            ->where(function ($q) {
                $q->whereNull('push_attempted_at')->orWhere('push_attempted_at', '<=', now()->subMinutes(5));
            })->chunkById(100, function ($rows) {
                foreach ($rows as $n) {
                    if (!in_array($n->notification_type, ['emergency_support', 'activity_reminder', 'treatment_due', 'treatment_reminder', 'daily_checkin'], true)) {
                        continue; // Other domains need their own current authorization check before retry.
                    }
                    if ($n->notification_type !== 'emergency_support' && !app(ConsentService::class)->active($n->user_id, 'HEALTH_DATA_PROCESSING')) {
                        $n->forceFill(['push_status' => 'cancelled'])->save();
                        continue;
                    }
                    if ($n->notification_type === 'emergency_support') {
                        $parts = explode(':', $n->dedupe_key);
                        $alert = \App\Models\SupportAlert::find($parts[1] ?? '');
                        $allowed = $alert && $alert->status === 'ACTIVE' && CaregiverLink::where('patient_user_id', $alert->patient_id)
                            ->where('caregiver_user_id', $n->user_id)->where('invitation_status', 'accepted')
                            ->whereIn('id', CaregiverPermission::where('can_receive_support_alert', true)->select('caregiver_link_id'))->exists();
                        if (!$allowed) {
                            $n->forceFill(['push_status' => 'cancelled'])->save();
                            continue;
                        }
                    }
                    $this->push($n, $n->user_id);
                }
            });
    }
    public function supportAlert(string $patient): void
    {
        $c = app(ConsentService::class);
        if (
            !$c->active($patient, "CAREGIVER_ALERT") ||
            !$c->active($patient, "HEALTH_DATA_PROCESSING")
        ) {
            return;
        }
        foreach (
            CaregiverLink::where("patient_user_id", $patient)
                ->where("invitation_status", "accepted")
                ->get()
            as $l
        ) {
            if (
                CaregiverPermission::where("caregiver_link_id", $l->id)
                    ->where("can_receive_support_alert", true)
                    ->exists()
            ) {
                $this->send(
                    $l->caregiver_user_id,
                    "support_alert",
                    "support:" . $l->id . ":" . now()->format("Y-m-d-H"),
                );
            }
        }
    }
}
