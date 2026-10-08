<?php
namespace App\Models;
class ActivityRecommendation extends OwnedRecord
{
    protected $table = "activity_recommendations";
    protected function casts(): array
    {
        return ["completed_at" => "datetime", "metadata" => "array"];
    }
}
