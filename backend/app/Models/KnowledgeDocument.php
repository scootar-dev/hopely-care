<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
class KnowledgeDocument extends Model
{
    use HasUuids;
    protected $guarded = [];
    protected function casts(): array { return ['document' => 'array', 'indexed' => 'boolean']; }
}
