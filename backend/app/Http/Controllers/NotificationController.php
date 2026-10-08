<?php
namespace App\Http\Controllers;
use App\Models\{DeviceToken, CareNotification};
use Illuminate\Http\Request;
class NotificationController extends Controller
{
    public function index(Request $r)
    {
        return $this->ok(
            CareNotification::where("user_id", $r->user()->id)
                ->latest()
                ->limit(50)
                ->get(["id", "title", "body", "notification_type", "read_at", "created_at"]),
        );
    }
    public function read(Request $r)
    {
        $n = CareNotification::where("user_id", $r->user()->id)->findOrFail($r->route("id"));
        $n->read_at = now();
        $n->save();
        return $this->ok();
    }
    public function device(Request $r)
    {
        $v = $r->validate([
            "token" => "required|string|max:4096",
            "platform" => "required|in:android,ios",
        ]);
        $hash = hash("sha256", $v["token"]);
        $d = DeviceToken::firstOrNew(["token_hash" => $hash]);
        $d->forceFill(["user_id" => $r->user()->id, ...$v])->save();
        return $this->ok(["id" => $d->id]);
    }
    public function removeDevice(Request $r)
    {
        DeviceToken::where("user_id", $r->user()->id)->where("id", $r->route("id"))->delete();
        return $this->ok();
    }
}
