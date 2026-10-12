<?php
namespace App\Models;

use Illuminate\Database\Eloquent\SoftDeletes;

class CommunityComment extends OwnedRecord
{
    use SoftDeletes;
    protected function casts(): array
    {
        return [
            "content" => "encrypted",
            "moderation_meta" => "encrypted:array",
            "revision" => "integer",
            "reviewed_at" => "datetime"
        ];
    }
    public function post()
    {
        return $this->belongsTo(CommunityPost::class, "post_id");
    }
    public function author()
    {
        return $this->belongsTo(User::class, "user_id");
    }
}
