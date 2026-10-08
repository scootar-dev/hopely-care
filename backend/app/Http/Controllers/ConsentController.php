<?php
namespace App\Http\Controllers;
use App\Models\Consent;
use App\Services\ConsentService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
class ConsentController extends Controller
{
    public function index(Request $r)
    {
        return $this->ok(Consent::where("user_id", $r->user()->id)->get());
    }
    public function update(Request $r, ConsentService $service)
    {
        $v = $r->validate([
            "consent_type" => ["required", Rule::in(ConsentService::TYPES)],
            "accepted" => "required|boolean",
        ]);
        $service->set($r->user()->id, $v["consent_type"], $v["accepted"]);
        return $this->index($r);
    }
}
