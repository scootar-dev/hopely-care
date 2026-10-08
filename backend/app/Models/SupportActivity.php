<?php
namespace App\Models;
class SupportActivity extends OwnedRecord
{
    protected $table = "support_activities";
    protected function casts(): array
    {
        return [
            "suitability_tags" => "array",
            "active" => "boolean",
            "medically_reviewed" => "boolean",
            "steps" => "array",
        ];
    }
}
