<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class Community extends Model
{
    use HasUuids;
    protected $guarded = ["id"];
    protected function casts(): array
    {
        return ["is_active" => "boolean"];
    }
    public function members()
    {
        return $this->hasMany(CommunityMember::class);
    }
    public function posts()
    {
        return $this->hasMany(CommunityPost::class);
    }
}
