<?php
namespace App\Services;
use App\Models\{Consent, JournalAiInsight, AiInsightSnapshot, ActivityRecommendation, DailyCheckin};
use Illuminate\Support\Facades\DB;
class ConsentService
{
    const TYPES = [
        "HEALTH_DATA_PROCESSING",
        "AI_JOURNAL_ANALYSIS",
        "AI_CHAT_CONTEXT",
        "CAREGIVER_WELLBEING_SHARE",
        "CAREGIVER_ALERT"
    ];
    public function active(string $id, string $type): bool
    {
        return Consent::where("user_id", $id)
            ->where("consent_type", $type)
            ->where("accepted", true)
            ->whereNull("revoked_at")
            ->exists();
    }
    public function fingerprint(string $id): string
    {
        return hash(
            "sha256",
            \App\Models\User::findOrFail($id)->consent_revision .
                ":" .
                Consent::where("user_id", $id)->orderBy("consent_type")->get()->toJson()
        );
    }
    public function withCurrent(string $id, string $fingerprint, \Closure $callback): mixed
    {
        return DB::transaction(function () use ($id, $fingerprint, $callback) {
            \App\Models\User::whereKey($id)->lockForUpdate()->firstOrFail();
            abort_unless(hash_equals($fingerprint, $this->fingerprint($id)), 409);
            return $callback();
        });
    }
    public function set(string $id, string $type, bool $accepted): void
    {
        DB::transaction(function () use ($id, $type, $accepted) {
            $user = \App\Models\User::whereKey($id)->lockForUpdate()->firstOrFail();
            $user->increment("consent_revision");
            $c = Consent::firstOrNew(["user_id" => $id, "consent_type" => $type]);
            $c->forceFill([
                "user_id" => $id,
                "accepted" => $accepted,
                "accepted_at" => $accepted ? now() : null,
                "revoked_at" => $accepted ? null : now(),
                "consent_version" => "1.0"
            ])->save();
            if (!$accepted) {
                JournalAiInsight::where("user_id", $id)->delete();
                AiInsightSnapshot::where("user_id", $id)->delete();
                ActivityRecommendation::where("user_id", $id)->delete();
                DailyCheckin::where("user_id", $id)->update(["emotion_signal" => null]);
            }
            app(AuditService::class)->record(
                $id,
                $accepted ? "consent.accepted" : "consent.revoked",
                $type
            );
        });
    }
}
