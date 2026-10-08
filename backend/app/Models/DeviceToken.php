<?php
namespace App\Models;
class DeviceToken extends OwnedRecord
{
    protected $table = "device_tokens";
    protected function casts(): array
    {
        return ["token" => "encrypted"];
    }
}
