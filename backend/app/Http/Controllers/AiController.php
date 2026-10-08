<?php
namespace App\Http\Controllers;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use App\Services\AiApplicationService;
class AiController extends Controller
{
    public function __construct(private AiApplicationService $service) {}
    public function analyzeJournal(Request $r)
    {
        return $this->ok($this->service->analyzeJournal($r->user()->id, $r->route("id")));
    }
    public function analyzeCheckin(Request $r)
    {
        return $this->ok($this->service->analyzeCheckin($r->user()->id, $r->route("id")));
    }
    public function insights(Request $r)
    {
        $v = $r->validate(["days" => ["sometimes", Rule::in([7, 14, 30])]]);
        return $this->ok($this->service->insights($r->user()->id, (int) ($v["days"] ?? 14)));
    }
    public function sessions(Request $r)
    {
        return $this->ok($this->service->sessions($r->user()->id));
    }
    public function messages(Request $r)
    {
        return $this->ok($this->service->messages($r->user()->id, $r->route("id")));
    }
    public function chat(Request $r)
    {
        $v = $r->validate([
            "message" => "required|string|max:4000",
            "session_id" => "nullable|uuid",
        ]);
        return $this->ok($this->service->chat($r->user()->id, $v));
    }
    public function activities(Request $r)
    {
        return $this->ok($this->service->activities());
    }
    public function recommended(Request $r)
    {
        return $this->ok($this->service->recommended($r->user()->id));
    }
    public function complete(Request $r)
    {
        return $this->ok($this->service->complete($r->user()->id, $r->route("id")));
    }
    public function summary(Request $r)
    {
        $v = $r->validate([
            "days" => ["required", Rule::in([7, 14, 30])],
            "reported_concerns" => "sometimes|array|max:5",
            "reported_concerns.*" => "string|max:1000",
        ]);
        return $this->ok($this->service->summary($r->user()->id, $v));
    }
    public function knowledge(Request $r)
    {
        $v = $r->validate(["question" => "required|string|max:2000"]);
        return $this->ok($this->service->knowledge($v));
    }
}
