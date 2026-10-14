<?php
namespace App\Policies;

use App\Models\{CommunityPost, User};
use App\Services\CommunityService;

class CommunityPostPolicy
{
    public function view(User $user, CommunityPost $post): bool
    {
        return app(CommunityService::class)->posts($user)->whereKey($post->id)->exists();
    }
    public function update(User $user, CommunityPost $post): bool
    {
        return $post->user_id === $user->id &&
            $post->moderation_status !== "removed" &&
            $user->can("participate", $post->community);
    }
    public function delete(User $user, CommunityPost $post): bool
    {
        return $post->user_id === $user->id;
    }
}
