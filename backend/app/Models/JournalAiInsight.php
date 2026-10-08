<?php
namespace App\Models;
class JournalAiInsight extends OwnedRecord
{
    protected $table = "journal_ai_insights";
    protected function casts(): array
    {
        return ["emotion_scores" => "array", "themes" => "array"];
    }
}
