<?php
namespace App\Models;
class AiInsightSnapshot extends OwnedRecord
{
    protected $table = "ai_insight_snapshots";
    protected function casts(): array
    {
        return ["report_json" => "array"];
    }
}
