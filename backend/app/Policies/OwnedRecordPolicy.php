<?php
namespace App\Policies;
use App\Models\{User, OwnedRecord};
class OwnedRecordPolicy
{
    public function access(User $user, OwnedRecord $record): bool
    {
        return $user->role === "PATIENT" && (string) $record->user_id === (string) $user->id;
    }
}
