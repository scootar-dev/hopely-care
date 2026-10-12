<?php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CommunityPostResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            "id" => $this->id,
            "community_id" => $this->community_id,
            "community_name" => $this->community->name,
            "author" => [
                "id" => $this->user_id,
                "display_name" => $this->author?->communityProfile?->display_name ?? "Anggota"
            ],
            "is_own" => $this->user_id === $request->user()->id,
            "content" => $this->content,
            "has_image" => $this->image_path !== null,
            "is_demo" => $this->is_demo,
            "moderation_status" => $this->moderation_status,
            "revision" => $this->revision,
            "created_at" => $this->created_at?->toISOString(),
            "updated_at" => $this->updated_at?->toISOString(),
            "comment_count" => (int) $this->comments_count,
            "reaction_count" => (int) $this->reactions_count,
            "my_reaction" => $this->reactions->first()?->reaction_type,
            "can_participate" =>
                $this->moderation_status === "approved" &&
                $request->user()->can("participate", $this->community)
        ];
    }
}
