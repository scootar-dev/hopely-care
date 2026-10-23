<?php
namespace App\Http\Controllers;
use App\Models\{SupportAlert, User};
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SupportAlertController extends Controller
{
    private function recipients(string $patient)
    {
        return DB::table('caregiver_links as l')
            ->join('caregiver_permissions as p', 'p.caregiver_link_id', '=', 'l.id')
            ->join('users as u', 'u.id', '=', 'l.caregiver_user_id')
            ->where('l.patient_user_id', $patient)->where('l.invitation_status', 'accepted')
            ->where('p.can_receive_support_alert', true)->where('u.role', 'CAREGIVER')
            ->distinct()->pluck('u.id');
    }
    private function visible(SupportAlert $alert, User $user): bool
    {
        return ($user->role === 'PATIENT' && $alert->patient_id === $user->id) ||
            ($user->role === 'CAREGIVER' && $this->recipients($alert->patient_id)->contains($user->id) &&
            DB::table('support_alert_recipients')->where('alert_id', $alert->id)->where('caregiver_id', $user->id)->exists());
    }
    private function data(SupportAlert $a): array
    {
        return [...$a->toArray(), 'patient_name' => User::find($a->patient_id)?->name,
            'acknowledged_name' => $a->acknowledged_by ? User::find($a->acknowledged_by)?->name : null,
            'recipient_count' => DB::table('support_alert_recipients')->where('alert_id', $a->id)->count()];
    }
    public function active(Request $r)
    {
        $query = SupportAlert::whereIn('status', ['ACTIVE', 'ACKNOWLEDGED']);
        if ($r->user()->role === 'PATIENT') {
            $query->where('patient_id', $r->user()->id);
        } else {
            $query->whereIn('id', DB::table('support_alert_recipients')->where('caregiver_id', $r->user()->id)->select('alert_id'));
        }
        $alerts = $query->latest()->get()
            ->filter(fn($a) => $this->visible($a, $r->user()))->map(fn($a) => $this->data($a))->values();
        return $this->ok(['alerts' => $alerts, 'eligible_count' => $r->user()->role === 'PATIENT' ? $this->recipients($r->user()->id)->count() : null]);
    }
    public function store(Request $r)
    {
        $r->validate(['patient_id' => 'prohibited', 'status' => 'prohibited', 'type' => 'prohibited']);
        $a = DB::transaction(function () use ($r) {
            User::whereKey($r->user()->id)->lockForUpdate()->firstOrFail();
            $existing = SupportAlert::where('patient_id', $r->user()->id)->whereIn('status', ['ACTIVE', 'ACKNOWLEDGED'])->first();
            if ($existing) return $existing;
            $recipients = $this->recipients($r->user()->id);
            abort_if($recipients->isEmpty(), 422, 'Belum ada pendamping yang terhubung dan diberi izin Bantuan Cepat.');
            $a = SupportAlert::create(['patient_id' => $r->user()->id, 'type' => 'EMERGENCY_SUPPORT', 'status' => 'ACTIVE']);
            foreach ($recipients as $id) {
                DB::table('support_alert_recipients')->insert(['alert_id' => $a->id, 'caregiver_id' => $id]);
                app(NotificationService::class)->send($id, 'emergency_support', 'emergency:'.$a->id.':'.$id);
            }
            return $a;
        });
        return $this->ok($this->data($a), 201);
    }
    public function transition(Request $r, string $id, string $action)
    {
        $a = DB::transaction(function () use ($r, $id, $action) {
            $a = SupportAlert::whereKey($id)->lockForUpdate()->firstOrFail();
            abort_unless($this->visible($a, $r->user()), 403);
            if ($action === 'acknowledge') {
                abort_unless($r->user()->role === 'CAREGIVER', 403);
                abort_unless($a->status === 'ACTIVE', 409, 'Alert sudah ditanggapi atau selesai.');
                $a->fill(['status' => 'ACKNOWLEDGED', 'acknowledged_by' => $r->user()->id, 'acknowledged_at' => now()]);
            } else {
                if ($action === 'cancel') {
                    abort_unless($r->user()->role === 'PATIENT', 403);
                    abort_unless($a->status === 'ACTIVE', 409);
                }
                abort_if($a->status === 'RESOLVED', 409);
                $a->fill(['status' => 'RESOLVED', 'resolved_at' => now()]);
            }
            $a->save();
            foreach ($this->recipients($a->patient_id) as $recipient) {
                if (DB::table('support_alert_recipients')->where('alert_id', $a->id)->where('caregiver_id', $recipient)->exists()) {
                    app(NotificationService::class)->send($recipient, 'emergency_support_update', 'emergency:'.$a->id.':'.$a->status.':'.$recipient);
                }
            }
            return $a;
        });
        return $this->ok($this->data($a));
    }
}
