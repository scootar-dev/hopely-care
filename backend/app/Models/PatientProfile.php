<?php
namespace App\Models;
class PatientProfile extends OwnedRecord
{
    protected $table = "patient_profiles";
    protected function casts(): array
    {
        return [
            "cancer_context" => "encrypted",
            "birth_year" => "integer",
            "onboarding_completed" => "boolean",
        ];
    }
}
