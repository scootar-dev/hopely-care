<?php
namespace App\Models;

class BlockedUser extends OwnedRecord
{
    public const UPDATED_AT = null;
    public function blocked()
    {
        return $this->belongsTo(User::class, "blocked_user_id");
    }
}
