<?php
namespace App\Models;

class CommunityPreference extends OwnedRecord
{
    protected function casts(): array
    {
        return [
            "notifications_enabled" => "boolean",
            "recommendation_enabled" => "boolean",
            "interests" => "encrypted:array"
        ];
    }
}
