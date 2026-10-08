<?php
namespace App\Http\Controllers;
use Illuminate\Http\Request;
use App\Services\AiClient;
use App\Models\SupportActivity;
class AdminController extends Controller
{
    public function ingest(Request $r, AiClient $ai)
    {
        $v = $r->validate([
            "source_id" => "required|string|max:100",
            "title" => "required|string|max:300",
            "publisher" => "required|string|max:200",
            "source_url" => "nullable|url|max:1000",
            "published_at" => "nullable|date",
            "document_version" => "required|string|max:80",
            "reviewed_by" => "required|string|max:200",
            "reviewed" => "required|accepted",
            "text" => "required|string|max:200000",
        ]);
        return $this->ok($ai->post("/v1/knowledge/ingest", $v));
    }
    public function activity(Request $r)
    {
        $v = $r->validate([
            "title" => "required|string|max:150",
            "description" => "required|string|max:2000",
            "category" => "required|string|max:50",
            "duration_minutes" => "required|integer|between:1,60",
            "suitability_tags" => "required|array|max:15",
            "suitability_tags.*" => "string|max:60",
            "steps" => "required|array|min:1|max:20",
            "steps.*" => "string|max:600",
            "contraindication_notes" => "nullable|string|max:1000",
            "medically_reviewed" => "required|boolean",
            "active" => "required|boolean",
        ]);
        $a = $r->route("id") ? SupportActivity::findOrFail($r->route("id")) : new SupportActivity();
        $a->fill($v)->save();
        return $this->ok($a);
    }
}
