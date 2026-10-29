<?php
namespace App\Policies;

use App\Models\{Community, CommunityMember, User};

class CommunityPolicy
{
    public function view(User $user, Community $community): bool
    {
        return $community->is_active &&
            !CommunityMember::where("community_id", $community->id)
                ->where("user_id", $user->id)
                ->where("status", "banned")
                ->exists();
    }
    public function join(User $user, Community $community): bool
    {
        return $this->view($user, $community);
    }
    public function participate(User $user, Community $community): bool
    {
        return $this->view($user, $community) &&
            CommunityMember::where("community_id", $community->id)
                ->where("user_id", $user->id)
                ->where("status", "active")
                ->exists();
    }
    public function moderate(User $user, Community $community): bool
    {
        return in_array($user->role, ['ADMIN', 'SUPER_ADMIN', 'COMMUNITY_MODERATOR'], true) ||
            ($community->is_active &&
                CommunityMember::where("community_id", $community->id)
                    ->where("user_id", $user->id)
                    ->where("status", "active")
                    ->whereIn("role", ["moderator", "admin"])
                    ->exists());
    }
}
