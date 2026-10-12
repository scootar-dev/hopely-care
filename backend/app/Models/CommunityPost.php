<?php
namespace App\Models;

use Illuminate\Database\Eloquent\SoftDeletes;

class CommunityPost extends OwnedRecord
{
    use SoftDeletes;
    protected function casts(): array
    {
        return [
            "content" => "encrypted",
            "moderation_meta" => "encrypted:array",
            "revision" => "integer",
            "is_demo" => "boolean",
            "reviewed_at" => "datetime"
        ];
    }
    public function community()
    {
        return $this->belongsTo(Community::class);
    }
    public function author()
    {
        return $this->belongsTo(User::class, "user_id");
    }
    public function comments()
    {
        return $this->hasMany(CommunityComment::class, "post_id");
    }
    public function reactions()
    {
        return $this->hasMany(CommunityReaction::class, "post_id");
    }
}
