<?php
namespace App\Http\Requests;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
class RecordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === "PATIENT";
    }
    public function rules(): array
    {
        $kind = $this->route("kind");
        $partial = $this->isMethod("PUT");
        $required = $partial ? ["sometimes", "required"] : ["required"];
        $tz =
            \App\Models\PatientProfile::where("user_id", $this->user()->id)->value("timezone") ??
            "Asia/Jakarta";
        $today = now($tz)->toDateString();
        $score = [...$required, "integer", "between:1,5"];
        $text = ["nullable", "string", "max:4000"];
        return match ($kind) {
            "checkins" => [
                "checkin_date" => [
                    ...$required,
                    "date_format:Y-m-d",
                    "before_or_equal:" . $today,
                    Rule::unique("daily_checkins")
                        ->where("user_id", $this->user()->id)
                        ->ignore($this->route("id")),
                ],
                "mood_score" => $score,
                "anxiety_score" => $score,
                "energy_score" => $score,
                "sleep_score" => $score,
                "pain_score" => $score,
                "optional_note" => $text,
                "ai_analysis_allowed" => ["sometimes", "boolean"],
            ],
            "symptoms" => [
                "logged_at" => [...$required, "date", "before_or_equal:now"],
                "pain" => $score,
                "fatigue" => $score,
                "nausea" => $score,
                "dizziness" => $score,
                "appetite" => $score,
                "sleep_quality" => $score,
                "optional_note" => $text,
            ],
            "treatments" => [
                "title" => [...$required, "string", "max:150"],
                "treatment_type" => [...$required, "string", "max:80"],
                "scheduled_at" => [...$required, "date"],
                "location" => ["nullable", "string", "max:500"],
                "notes" => $text,
                "status" => ["sometimes", Rule::in(["scheduled", "completed", "cancelled"])],
            ],
            "journals" => [
                "title" => ["nullable", "string", "max:150"],
                "content" => [...$required, "string", "max:12000"],
                "journal_date" => [...$required, "date_format:Y-m-d", "before_or_equal:" . $today],
                "ai_analysis_allowed" => ["sometimes", "boolean"],
            ],
            default => [],
        };
    }
}
