<?php
namespace App\Models;

class CommunityMember extends OwnedRecord
{
    protected function casts(): array
    {
        return ["joined_at" => "datetime"];
    }
    public function community()
    {
        return $this->belongsTo(Community::class);
    }
}
