<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CommunityReportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }
    public function rules(): array
    {
        return [
            "reportable_type" => ["required", "in:post,comment"],
            "reportable_id" => ["required", "uuid"],
            "reason" => ["required", "in:misinformation,harassment,spam,privacy,unsafe,other"],
            "description" => ["nullable", "string", "max:1000"]
        ];
    }
}
