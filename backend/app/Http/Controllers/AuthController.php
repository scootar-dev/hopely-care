<?php
namespace App\Http\Controllers;
use App\Models\{User, PatientProfile};
use App\Services\ProfilePhotoService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\{Hash, DB};
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\Rule;
class AuthController extends Controller
{
    public function register(Request $r)
    {
        $v = $r->validate([
            "name" => "required|string|max:100",
            "email" => "required|email|max:254|unique:users",
            "password" => ["required", "confirmed", Password::min(12)],
            "role" => ["required", Rule::in(["PATIENT", "CAREGIVER"])],
        ]);
        $u = DB::transaction(function () use ($v) {
            $u = new User();
            $u->forceFill([
                "name" => $v["name"],
                "email" => strtolower($v["email"]),
                "password" => $v["password"],
                "role" => $v["role"],
            ])->save();
            if ($u->role === "PATIENT") {
                $p = new PatientProfile();
                $p->forceFill([
                    "user_id" => $u->id,
                    "display_name" => $u->name,
                    "timezone" => "Asia/Jakarta",
                ])->save();
            }
            return $u;
        });
        return $this->ok(["user" => $u, "token" => $u->createToken("mobile")->plainTextToken], 201);
    }
    public function login(Request $r)
    {
        $v = $r->validate(["email" => "required|email", "password" => "required|string"]);
        $u = User::where("email", strtolower($v["email"]))->first();
        abort_unless($u && Hash::check($v["password"], $u->password), 401);
        return $this->ok(["user" => $u, "token" => $u->createToken("mobile")->plainTextToken]);
    }
    public function me(Request $r)
    {
        return $this->ok([
            "user" => $r->user(),
            "profile" => PatientProfile::where("user_id", $r->user()->id)->first(),
        ]);
    }
    public function profile(Request $r)
    {
        $v = $r->validate([
            "display_name" => "required|string|max:100",
            "birth_year" => "nullable|integer|between:1900," . date("Y"),
            "cancer_context" => "nullable|string|max:1000",
            "treatment_phase" => "nullable|string|max:100",
            "timezone" => "required|timezone",
            "onboarding_completed" => "sometimes|boolean",
        ]);
        $p = PatientProfile::where("user_id", $r->user()->id)->firstOrFail();
        $p->fill($v)->save();
        return $this->ok($p);
    }
    public function logout(Request $r)
    {
        $r->user()->currentAccessToken()?->delete();
        return $this->ok();
    }
    public function destroy(Request $r, ProfilePhotoService $photos)
    {
        $v = $r->validate(["password" => "required|string"]);
        abort_unless(Hash::check($v["password"], $r->user()->password), 403);
        DB::transaction(function () use ($r, $photos) {
            $photos->delete($r->user());
            $r->user()->tokens()->delete();
            $r->user()->delete();
        });
        return $this->ok();
    }
}
