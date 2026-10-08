<?php
namespace App\Services;
use App\Models\{
    JournalAiInsight,
    ChatSession,
    ChatMessage,
    AiInsightSnapshot,
    SupportActivity,
    ActivityRecommendation,
    DoctorVisitReport
};
class AiApplicationService
{
    public function __construct(
        private AiClient $ai,
        private ContextService $context,
        private ConsentService $consents,
        private RecordService $records,
        private NotificationService $notifications,
    ) {}
    private function guardConsent(string $id, string $type): string
    {
        abort_unless($this->consents->active($id, $type), 403);
        return $this->consents->fingerprint($id);
    }
    private function unchanged(string $id, string $before): void
    {
        abort_unless(hash_equals($before, $this->consents->fingerprint($id)), 409);
    }
    public function analyzeJournal(string $id, string $recordId)
    {
        $j = $this->records->owned("journals", $recordId);
        $before = $this->guardConsent($id, "AI_JOURNAL_ANALYSIS");
        abort_unless($j->ai_analysis_allowed, 403);
        $contentHash = hash("sha256", $j->content);
        $out = $this->ai->post("/v1/ai/emotion/analyze", ["text" => $j->content]);
        $this->consents->withCurrent($id, $before, function () use ($id, $j, $out, $contentHash) {
            $j = \App\Models\Journal::whereKey($j->id)->lockForUpdate()->firstOrFail();
            abort_unless(
                $j->ai_analysis_allowed && hash_equals($contentHash, hash("sha256", $j->content)),
                409,
            );
            $e = JournalAiInsight::firstOrNew(["journal_id" => $j->id]);
            $e->forceFill([
                "user_id" => $id,
                "primary_emotion" => $out["primary_emotion"],
                "emotion_scores" => $out["scores"],
                "themes" => $out["themes"],
                "generated_at" => now(),
                "model_version" => $out["metadata"]["model_version"],
            ])->save();
        });
        return $out;
    }
    public function analyzeCheckin(string $id, string $recordId)
    {
        $c = $this->records->owned("checkins", $recordId);
        $before = $this->guardConsent($id, "AI_JOURNAL_ANALYSIS");
        abort_unless($c->ai_analysis_allowed && $c->optional_note, 403);
        $hash = hash("sha256", $c->optional_note);
        $out = $this->ai->post("/v1/ai/emotion/analyze", ["text" => $c->optional_note]);
        $this->consents->withCurrent($id, $before, function () use ($c, $hash, $out) {
            $c = \App\Models\DailyCheckin::whereKey($c->id)->lockForUpdate()->firstOrFail();
            abort_unless(
                $c->ai_analysis_allowed &&
                    hash_equals($hash, hash("sha256", $c->optional_note ?? "")),
                409,
            );
            $c->emotion_signal = $out;
            $c->save();
        });
        return $out;
    }
    public function insights(string $id, int $days)
    {
        $before = $this->consents->fingerprint($id);
        $out = $this->ai->post("/v1/ai/trend/analyze", [
            "context" => $this->context->build($id, $days),
        ]);
        $this->consents->withCurrent($id, $before, function () use ($id, $out) {
            $s = new AiInsightSnapshot();
            $s->forceFill([
                "user_id" => $id,
                "snapshot_date" => now()->toDateString(),
                "report_json" => $out,
                "model_version" => $out["metadata"]["model_version"],
            ])->save();
        });
        return $out;
    }
    public function sessions(string $id)
    {
        return ChatSession::where("user_id", $id)
            ->latest()
            ->limit(30)
            ->get(["id", "title", "created_at"]);
    }
    public function messages(string $id, string $recordId)
    {
        $session = ChatSession::where("user_id", $id)->findOrFail($recordId);
        return ChatMessage::where("chat_session_id", $session->id)
            ->oldest()
            ->get(["id", "sender", "content", "safety_level", "created_at"]);
    }
    public function chat(string $id, array $v)
    {
        $before = $this->guardConsent($id, "AI_CHAT_CONTEXT");
        $session = isset($v["session_id"])
            ? ChatSession::where("user_id", $id)->findOrFail($v["session_id"])
            : null;
        $history = $session
            ? ChatMessage::where("chat_session_id", $session->id)
                ->latest()
                ->limit(8)
                ->get(["sender", "content"])
                ->reverse()
                ->values()
                ->toArray()
            : [];
        $out = $this->ai->post("/v1/ai/companion", [
            "user_id" => $id,
            "message" => $v["message"],
            "context" => $this->context->build($id),
            "history" => $history,
        ]);
        $this->unchanged($id, $before);
        $session = $this->consents->withCurrent($id, $before, function () use (
            $session,
            $id,
            $v,
            $out,
        ) {
            if (!$session) {
                $session = new ChatSession();
                $session->forceFill(["user_id" => $id])->save();
            }
            foreach ([["user", $v["message"]], ["assistant", $out["reply"]]] as [$sender, $text]) {
                $m = new ChatMessage();
                $m->forceFill([
                    "user_id" => $id,
                    "chat_session_id" => $session->id,
                    "sender" => $sender,
                    "content" => $text,
                    "safety_level" => $out["safety_signal"],
                ])->save();
            }
            return $session;
        });
        if ($out["safety_signal"] === "URGENT") {
            $this->notifications->supportAlert($id);
        }
        return [...$out, "session_id" => $session->id];
    }
    public function activities()
    {
        return SupportActivity::where("active", true)->get();
    }
    public function recommended(string $id)
    {
        $before = $this->consents->fingerprint($id);
        $activities = SupportActivity::where("active", true)->get();
        if ($activities->isEmpty()) {
            return [];
        }
        $out = $this->ai->post("/v1/ai/recommendations", [
            "context" => $this->context->build($id, 14),
            "activities" => $activities
                ->map(
                    fn($a) => collect($a->toArray())
                        ->only([
                            "id",
                            "title",
                            "description",
                            "category",
                            "duration_minutes",
                            "suitability_tags",
                            "contraindication_notes",
                        ])
                        ->all(),
                )
                ->values()
                ->all(),
        ]);
        $results = $this->consents->withCurrent($id, $before, function () use (
            $id,
            $out,
            $activities,
        ) {
            $results = [];
            foreach ($out["recommendations"] as $rec) {
                abort_unless($activities->contains("id", $rec["activity_id"]), 503);
                $a = new ActivityRecommendation();
                $a->forceFill([
                    "user_id" => $id,
                    "support_activity_id" => $rec["activity_id"],
                    "reason" => $rec["reason"],
                    "metadata" => $out["metadata"],
                    "generated_at" => now(),
                ])->save();
                $results[] = [
                    "id" => $a->id,
                    "activity" => $activities->firstWhere("id", $rec["activity_id"]),
                    "reason" => $a->reason,
                    "metadata" => $out["metadata"],
                ];
            }
            return $results;
        });
        return $results;
    }
    public function complete(string $id, string $recordId)
    {
        $a = ActivityRecommendation::where("user_id", $id)->findOrFail($recordId);
        $a->completed_at ??= now();
        $a->save();
        return $a;
    }
    public function summary(string $id, array $v)
    {
        $before = $this->consents->fingerprint($id);
        $ctx = $this->context->build($id, $v["days"]);
        $out = $this->ai->post("/v1/ai/doctor-summary", [
            "context" => $ctx,
            "reported_concerns" => $v["reported_concerns"] ?? [],
        ]);
        $report = $this->consents->withCurrent($id, $before, function () use ($id, $ctx, $out, $v) {
            $report = new DoctorVisitReport();
            $report
                ->forceFill([
                    "user_id" => $id,
                    "period_start" => \Carbon\Carbon::parse($ctx["as_of"])
                        ->subDays($v["days"] - 1)
                        ->toDateString(),
                    "period_end" => $ctx["as_of"],
                    "report_json" => $out,
                    "generated_at" => now(),
                ])
                ->save();
            return $report;
        });
        return ["id" => $report->id, ...$out];
    }
    public function knowledge(array $v)
    {
        return $this->ai->post("/v1/rag/query", $v);
    }
}
