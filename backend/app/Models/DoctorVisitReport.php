<?php
namespace App\Models;
class DoctorVisitReport extends OwnedRecord
{
    protected $table = "doctor_visit_reports";
    protected function casts(): array
    {
        return ["report_json" => "encrypted:array"];
    }
}
