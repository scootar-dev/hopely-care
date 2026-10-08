<?php
namespace App\Services;
use App\Models\AuditLog;
class AuditService
{
    public function record(string $actor, string $event, string $type, ?string $id = null): void
    {
        $a = new AuditLog();
        $a->forceFill([
            "actor_user_id" => $actor,
            "event" => $event,
            "resource_type" => $type,
            "resource_id" => $id,
            "metadata" => [],
        ])->save();
    }
}
