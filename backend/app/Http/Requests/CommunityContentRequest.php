<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CommunityContentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }
    protected function prepareForValidation(): void
    {
        if (is_string($this->input("content"))) {
            $this->merge(["content" => trim($this->input("content"))]);
        }
    }
    public function rules(): array
    {
        return [
            "content" => ["required", "string", "min:2", "max:4000"],
            "sharing_acknowledged" => ["required", "accepted"],
            "image" => [
                "nullable",
                "file",
                "image",
                "mimes:jpg,jpeg,png,webp",
                "max:2048",
                "dimensions:max_width=4096,max_height=4096"
            ],
            "revision" => ["sometimes", "integer", "min:1"]
        ];
    }
}
