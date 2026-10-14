<?php
namespace App\Models;

class CommunityReport extends OwnedRecord
{
    protected function casts(): array
    {
        return ["description" => "encrypted", "reviewed_at" => "datetime"];
    }
    public function community()
    {
        return $this->belongsTo(Community::class);
    }
}
