<?php
namespace App\Policies;

use App\Models\{CommunityComment, User};
use App\Services\CommunityService;

class CommunityCommentPolicy
{
    public function view(User $user, CommunityComment $comment): bool
    {
        return $comment->post &&
            $user->can("view", $comment->post) &&
            app(CommunityService::class)
                ->comments($user, $comment->post)
                ->whereKey($comment->id)
                ->exists();
    }
    public function delete(User $user, CommunityComment $comment): bool
    {
        return $comment->user_id === $user->id;
    }
}
