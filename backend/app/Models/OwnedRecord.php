<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
abstract class OwnedRecord extends Model
{
    use HasUuids;
    protected $guarded = ["id", "user_id"];
}
