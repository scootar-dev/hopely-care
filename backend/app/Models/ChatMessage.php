<?php
namespace App\Models;
class ChatMessage extends OwnedRecord
{
    protected $table = "chat_messages";
    protected function casts(): array
    {
        return ["content" => "encrypted"];
    }
}
