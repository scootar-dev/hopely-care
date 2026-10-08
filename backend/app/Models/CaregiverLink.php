<?php
namespace App\Models;
class CaregiverLink extends OwnedRecord
{
    protected $table = "caregiver_links";
    protected function casts(): array
    {
        return ["expires_at" => "datetime"];
    }
}
