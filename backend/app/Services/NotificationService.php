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
            "body" => "Ada pengingat baru. Buka Hopely Care untuk melihatnya.",
        ])->save();
        $file = config("services.firebase.credentials");
        $project = config("services.firebase.project_id");
        if (!$file || !$project || !is_readable($file)) {
            return;
        }
        try {
            $auth = new ServiceAccountCredentials(
                "https://www.googleapis.com/auth/firebase.messaging",
                json_decode(file_get_contents($file), true, 512, JSON_THROW_ON_ERROR),
            );
            $token = $auth->fetchAuthToken()["access_token"] ?? null;
            if (!$token) {
                return;
            }
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
                if ($r->status() === 404) {
                    $d->delete();
                }
            }
        } catch (\Throwable $e) {
            /* Never include credentials or payload in application logs. In-app notification remains available. */
        }
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
