<?php
namespace App\Services;
use App\Models\{DailyCheckin, SymptomLog, Treatment, Journal, JournalAiInsight, AiInsightSnapshot};
use Illuminate\Support\Facades\Gate;
class RecordService
{
    public function model(string $kind): string
    {
        return match ($kind) {
            "checkins" => DailyCheckin::class,
            "symptoms" => SymptomLog::class,
            "treatments" => Treatment::class,
            "journals" => Journal::class,
            default => abort(404),
        };
    }
    public function owned(string $kind, string $id)
    {
        $m = $this->model($kind)::findOrFail($id);
        Gate::authorize("access", $m);
        return $m;
    }
    public function save(string $user, string $kind, array $data, ?string $id = null)
    {
        $m = $id ? $this->owned($kind, $id) : new ($this->model($kind))();
        foreach (["scheduled_at", "logged_at"] as $key) {
            if (isset($data[$key])) {
                $data[$key] = \Carbon\Carbon::parse($data[$key])->utc();
            }
        }
        $m->fill($data);
        $m->user_id = $user;
        $m->save();
        if ($kind === "journals") {
            JournalAiInsight::where("journal_id", $m->id)->delete();
        }
        if ($kind === "checkins") {
            $m->emotion_signal = null;
            $m->save();
        }
        AiInsightSnapshot::where("user_id", $user)->delete();
        app(AuditService::class)->record(
            $user,
            $id ? "record.updated" : "record.created",
            $kind,
            $m->id,
        );
        return $m;
    }
}
