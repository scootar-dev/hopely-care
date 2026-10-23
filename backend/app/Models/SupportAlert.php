<?php
namespace App\Models;
class SupportAlert extends OwnedRecord
{
    protected function casts(): array
    {
        return ['acknowledged_at' => 'datetime', 'resolved_at' => 'datetime'];
    }
}
