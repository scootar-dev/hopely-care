<?php
namespace App\Models;
class SymptomLog extends OwnedRecord
{
    protected $table = "symptom_logs";
    protected function casts(): array
    {
        return ["logged_at" => "immutable_datetime", "optional_note" => "encrypted"];
    }
}
