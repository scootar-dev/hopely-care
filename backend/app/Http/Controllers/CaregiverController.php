<?php
namespace App\Http\Controllers;
use App\Models\{CaregiverLink, CaregiverPermission, User};
use App\Services\{CaregiverService, AiClient, ConsentService};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
class CaregiverController extends Controller
{
    public function invite(Request $r)
    {
        $v = $r->validate([
            "email" => "required|email|max:254",
            "relationship_label" => "required|string|max:80",
        ]);
        $recipient = User::where("email", strtolower($v["email"]))->first();
        if ($recipient && $recipient->role !== "CAREGIVER") {
            throw ValidationException::withMessages([
                "email" => "Gunakan email akun Kerabat atau email yang belum terdaftar. Akun Pasien tidak dapat menerima undangan pendamping.",
            ]);
        }
        $token = Str::random(48);
        $link = DB::transaction(function () use ($r, $v, $token) {
            $link = CaregiverLink::firstOrNew([
                "patient_user_id" => $r->user()->id,
                "invited_email" => strtolower($v["email"]),
            ]);
            abort_if($link->exists && $link->invitation_status === "accepted", 409);
            $link
                ->forceFill([
                    "relationship_label" => $v["relationship_label"],
                    "invitation_status" => "pending",
                    "caregiver_user_id" => null,
                    "invitation_hash" => hash("sha256", $token),
                    "expires_at" => now()->addHours(48),
                ])
                ->save();
            $p = CaregiverPermission::firstOrNew(["caregiver_link_id" => $link->id]);
            $p->forceFill(
                array_fill_keys(
                    [
                        "can_view_wellbeing_summary",
                        "can_view_treatment_schedule",
                        "can_receive_support_alert",
                        "can_view_symptom_summary",
                        "can_view_activity_status",
                    ],
                    false,
                ),
            )->save();
            return $link;
        });
        return $this->ok(
            ["id" => $link->id, "invitation_token" => $token, "expires_at" => $link->expires_at],
            201,
        );
    }
    public function accept(Request $r)
    {
        $v = $r->validate(["token" => "required|string|max:100"]);
        DB::transaction(function () use ($r, $v) {
            $link = CaregiverLink::where("invitation_hash", hash("sha256", $v["token"]))
                ->where("invited_email", $r->user()->email)
                ->where("invitation_status", "pending")
                ->where("expires_at", ">", now())
                ->lockForUpdate()
                ->firstOrFail();
            $link
                ->forceFill([
                    "caregiver_user_id" => $r->user()->id,
                    "invitation_status" => "accepted",
                    "invitation_hash" => null,
                ])
                ->save();
        });
        return $this->ok();
    }
    public function index(Request $r)
    {
        return $this->ok(
            CaregiverLink::where("patient_user_id", $r->user()->id)->get()->map(
                fn($l) => [
                    "id" => $l->id,
                    "relationship_label" => $l->relationship_label,
                    "invited_email" => $l->invited_email,
                    "invitation_status" => $l->invitation_status,
                    "permissions" => CaregiverPermission::where(
                        "caregiver_link_id",
                        $l->id,
                    )->first(),
                ],
            ),
        );
    }
    public function permissions(Request $r)
    {
        $l = CaregiverLink::where("patient_user_id", $r->user()->id)->findOrFail($r->route("id"));
        $keys = [
            "can_view_wellbeing_summary",
            "can_view_treatment_schedule",
            "can_receive_support_alert",
            "can_view_symptom_summary",
            "can_view_activity_status",
        ];
        $v = $r->validate(array_fill_keys($keys, "required|boolean"));
        $p = CaregiverPermission::where("caregiver_link_id", $l->id)->firstOrFail();
        $p->fill($v)->save();
        return $this->ok($p);
    }
    public function revoke(Request $r)
    {
        $l = CaregiverLink::where("patient_user_id", $r->user()->id)->findOrFail($r->route("id"));
        $l->forceFill(["invitation_status" => "revoked", "invitation_hash" => null])->save();
        return $this->ok();
    }
    public function patients(Request $r)
    {
        return $this->ok(
            CaregiverLink::where("caregiver_user_id", $r->user()->id)
                ->where("invitation_status", "accepted")
                ->get()
                ->map(
                    fn($l) => [
                        "patient_id" => $l->patient_user_id,
                        "name" => User::find($l->patient_user_id)?->name,
                        "relationship_label" => $l->relationship_label,
                    ],
                ),
        );
    }
    public function summary(Request $r, CaregiverService $s)
    {
        return $this->ok($s->summary($r->user()->id, $r->route("id")));
    }
    public function coach(Request $r, CaregiverService $s, AiClient $ai)
    {
        $v = $r->validate(["message" => "required|string|max:2000"]);
        $context = $s->summary($r->user()->id, $r->route("id"));
        unset($context["patient_id"], $context["permissions"]);
        $result = $ai->post("/v1/ai/caregiver-coach", [
            "message" => $v["message"],
            "context" => $context,
        ]);
        abort_unless(
            $context ===
                collect($s->summary($r->user()->id, $r->route("id")))
                    ->except(["patient_id", "permissions"])
                    ->all(),
            409,
        );
        return $this->ok($result);
    }
}
