<?php
namespace App\Models;
class CareNotification extends OwnedRecord
{
    protected $table = "notifications";
    protected function casts(): array
    {
        return ["read_at" => "datetime"];
    }
}
