<?php
namespace App\Models;
class ChatSession extends OwnedRecord
{
    protected $table = "chat_sessions";
    protected function casts(): array
    {
        return [];
    }
}
