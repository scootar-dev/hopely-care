<?php
namespace App\Services;
use App\Models\{
    CaregiverLink,
    CaregiverPermission,
    DailyCheckin,
    SymptomLog,
    Treatment,
    ActivityRecommendation
};
class CaregiverService
{
    public function link(string $caregiver, string $patient): CaregiverLink
    {
        return CaregiverLink::where("caregiver_user_id", $caregiver)
            ->where("patient_user_id", $patient)
            ->where("invitation_status", "accepted")
            ->firstOrFail();
    }
    public function summary(string $caregiver, string $patient): array
    {
        $link = $this->link($caregiver, $patient);
        $c = app(ConsentService::class);
        abort_unless(
            $c->active($patient, "HEALTH_DATA_PROCESSING") &&
                $c->active($patient, "CAREGIVER_WELLBEING_SHARE"),
            403,
        );
        $p = CaregiverPermission::where("caregiver_link_id", $link->id)->firstOrFail();
        $out = [
            "patient_id" => $patient,
            "permissions" => collect($p->toArray())
                ->filter(fn($v, $k) => str_starts_with($k, "can_"))
                ->all(),
        ];
        if ($p->can_view_wellbeing_summary) {
            $rows = DailyCheckin::where("user_id", $patient)
                ->where("checkin_date", ">=", now()->subDays(6)->toDateString())
                ->get();
            $out["wellbeing_summary"] = [
                "recorded_days" => $rows->count(),
                "mood" => $rows->avg("mood_score"),
                "anxiety" => $rows->avg("anxiety_score"),
                "energy" => $rows->avg("energy_score"),
                "sleep" => $rows->avg("sleep_score"),
            ];
        }
        if ($p->can_view_symptom_summary) {
            $rows = SymptomLog::where("user_id", $patient)
                ->where("logged_at", ">=", now()->subDays(7))
                ->get();
            $out["symptom_summary"] = ["record_count" => $rows->count()];
            foreach (
                ["pain", "fatigue", "nausea", "dizziness", "appetite", "sleep_quality"]
                as $k
            ) {
                $out["symptom_summary"][$k] = $rows->avg($k);
            }
        }
        if ($p->can_view_treatment_schedule) {
            $out["treatment_schedule"] = Treatment::where("user_id", $patient)
                ->where("scheduled_at", ">=", now())
                ->where("status", "scheduled")
                ->orderBy("scheduled_at")
                ->limit(5)
                ->get(["treatment_type", "scheduled_at"])
                ->toArray();
        }
        if ($p->can_view_activity_status) {
            $out["activity_status"] = [
                "completed_count" => ActivityRecommendation::where("user_id", $patient)
                    ->whereNotNull("completed_at")
                    ->where("completed_at", ">=", now()->subDays(7))
                    ->count(),
            ];
        }
        app(AuditService::class)->record($caregiver, "caregiver.summary.read", "patient", $patient);
        return $out;
    }
}
