<?php
namespace App\Http\Resources;
use Illuminate\Http\Resources\Json\JsonResource;
class RecordResource extends JsonResource
{
    public function toArray($request): array
    {
        return collect($this->resource->toArray())
            ->except(["user_id", "invitation_hash", "token", "token_hash"])
            ->all();
    }
}
