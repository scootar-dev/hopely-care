<?php
namespace App\Models;
class Treatment extends OwnedRecord
{
    protected $table = "treatments";
    protected function casts(): array
    {
        return [
            "scheduled_at" => "immutable_datetime",
            "notes" => "encrypted",
            "location" => "encrypted",
        ];
    }
}
