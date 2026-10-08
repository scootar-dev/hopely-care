<?php
namespace App\Models;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Laravel\Sanctum\HasApiTokens;
class User extends Authenticatable
{
    use HasApiTokens, HasUuids;
    protected $guarded = ["id", "role"];
    protected $hidden = ["password", "remember_token", "consent_revision"];
    protected function casts(): array
    {
        return ["password" => "hashed", "email_verified_at" => "datetime"];
    }
}
