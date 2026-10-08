<?php
namespace App\Services;
use App\Models\{
    DailyCheckin,
    SymptomLog,
    Treatment,
    JournalAiInsight,
    Journal,
    ActivityRecommendation,
    PatientProfile
};
class ContextService
{
    public function build(string $id, int $days = 7): array
    {
        $consent = app(ConsentService::class);
        abort_unless($consent->active($id, "HEALTH_DATA_PROCESSING"), 403);
        $tz = PatientProfile::where("user_id", $id)->value("timezone") ?? "Asia/Jakarta";
        $today = now($tz)->toDateString();
        $since = now($tz)
            ->startOfDay()
            ->subDays($days - 1);
        $checkins = DailyCheckin::where("user_id", $id)
            ->whereBetween("checkin_date", [$since->toDateString(), $today])
            ->orderBy("checkin_date")
            ->get();
        $emotions = [];
        if ($consent->active($id, "AI_JOURNAL_ANALYSIS")) {
            $journals = Journal::where("user_id", $id)
                ->where("ai_analysis_allowed", true)
                ->whereBetween("journal_date", [$since->toDateString(), $today])
                ->get()
                ->keyBy("id");
            foreach (
                JournalAiInsight::where("user_id", $id)
                    ->whereIn("journal_id", $journals->keys())
                    ->get()
                as $e
            ) {
                $emotions[] = [
                    "mode" => str_starts_with($e->model_version, "mock") ? "mock" : "live",
                    "date" => $journals[$e->journal_id]->journal_date,
                    "scores" => $e->emotion_scores,
                ];
            }
            foreach ($checkins as $c) {
                if ($c->ai_analysis_allowed && $c->emotion_signal) {
                    $emotions[] = [
                        "mode" => $c->emotion_signal["metadata"]["mode"] ?? "mock",
                        "date" => $c->checkin_date,
                        "scores" => $c->emotion_signal["scores"],
                    ];
                }
            }
        }
        return [
            "as_of" => $today,
            "timezone" => $tz,
            "period_days" => $days,
            "recent_checkins" => $checkins
                ->map(
                    fn($c) => collect($c->toArray())
                        ->only([
                            "checkin_date",
                            "mood_score",
                            "anxiety_score",
                            "energy_score",
                            "sleep_score",
                            "pain_score",
                        ])
                        ->all(),
                )
                ->values()
                ->all(),
            "recent_symptoms" => SymptomLog::where("user_id", $id)
                ->whereBetween("logged_at", [$since->copy()->utc(), now()])
                ->orderByDesc("logged_at")
                ->limit(200)
                ->get()
                ->map(
                    fn($s) => collect($s->toArray())
                        ->only([
                            "logged_at",
                            "pain",
                            "fatigue",
                            "nausea",
                            "dizziness",
                            "appetite",
                            "sleep_quality",
                        ])
                        ->all(),
                )
                ->all(),
            "treatments" => Treatment::where("user_id", $id)
                ->where("status", "!=", "cancelled")
                ->whereBetween("scheduled_at", [$since->copy()->utc(), now()->addDays(7)])
                ->orderBy("scheduled_at")
                ->limit(60)
                ->get(["treatment_type", "scheduled_at", "status"])
                ->toArray(),
            "next_treatment" => Treatment::where("user_id", $id)
                ->where("status", "scheduled")
                ->where("scheduled_at", ">=", now())
                ->orderBy("scheduled_at")
                ->first(["treatment_type", "scheduled_at"])
                ?->toArray(),
            "emotion_signals" => array_slice($emotions, -100),
            "completed_activities" => ActivityRecommendation::where("user_id", $id)
                ->whereNotNull("completed_at")
                ->where("completed_at", ">=", $since)
                ->limit(10)
                ->pluck("support_activity_id")
                ->all(),
            "consent" => [
                "health" => true,
                "journal_analysis" => $consent->active($id, "AI_JOURNAL_ANALYSIS"),
                "chat_context" => $consent->active($id, "AI_CHAT_CONTEXT"),
            ],
        ];
    }
}
