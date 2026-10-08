<?php
namespace App\Models;
class AuditLog extends OwnedRecord
{
    protected $table = "audit_logs";
    protected function casts(): array
    {
        return ["metadata" => "array"];
    }
}
