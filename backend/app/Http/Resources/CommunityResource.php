<?php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CommunityResource extends JsonResource
{
    public function toArray($request): array
    {
        $member = $this->members->first(); // Eager-loaded for the requesting user only.
        return [
            "id" => $this->id,
            "name" => $this->name,
            "slug" => $this->slug,
            "description" => $this->description,
            "category" => $this->category,
            "cancer_type" => $this->cancer_type,
            "treatment_phase" => $this->treatment_phase,
            "support_type" => $this->support_type,
            "member_count" => (int) $this->members_count,
            "post_count" => (int) $this->posts_count,
            "membership_status" => $member?->status,
            "membership_role" => $member?->role,
            "can_moderate" => $request->user()->can("moderate", $this->resource)
        ];
    }
}
