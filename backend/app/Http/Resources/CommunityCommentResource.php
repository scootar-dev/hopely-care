<?php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CommunityCommentResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            "id" => $this->id,
            "post_id" => $this->post_id,
            "author" => [
                "id" => $this->user_id,
                "display_name" => $this->author?->communityProfile?->display_name ?? "Anggota"
            ],
            "is_own" => $this->user_id === $request->user()->id,
            "content" => $this->content,
            "moderation_status" => $this->moderation_status,
            "revision" => $this->revision,
            "created_at" => $this->created_at?->toISOString()
        ];
    }
}
