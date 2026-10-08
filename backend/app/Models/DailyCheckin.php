<?php
namespace App\Models;
class DailyCheckin extends OwnedRecord
{
    protected $table = "daily_checkins";
    protected function casts(): array
    {
        return [
            "optional_note" => "encrypted",
            "ai_analysis_allowed" => "boolean",
            "emotion_signal" => "array",
        ];
    }
}
