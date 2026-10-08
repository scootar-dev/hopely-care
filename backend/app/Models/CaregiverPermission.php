<?php
namespace App\Models;
class CaregiverPermission extends OwnedRecord
{
    protected $table = "caregiver_permissions";
    protected function casts(): array
    {
        return [
            "can_view_wellbeing_summary" => "boolean",
            "can_view_treatment_schedule" => "boolean",
            "can_receive_support_alert" => "boolean",
            "can_view_symptom_summary" => "boolean",
            "can_view_activity_status" => "boolean",
        ];
    }
}
