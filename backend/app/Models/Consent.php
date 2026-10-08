<?php
namespace App\Models;
class Consent extends OwnedRecord
{
    protected $table = "consents";
    protected function casts(): array
    {
        return ["accepted" => "boolean", "accepted_at" => "datetime", "revoked_at" => "datetime"];
    }
}
