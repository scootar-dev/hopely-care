<?php
namespace App\Models;
class Journal extends OwnedRecord
{
    protected $table = "journals";
    protected function casts(): array
    {
        return [
            "title" => "encrypted",
            "content" => "encrypted",
            "ai_analysis_allowed" => "boolean",
        ];
    }
}
