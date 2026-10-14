<?php
namespace App\Http\Controllers;
use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password as PasswordRule;
use Illuminate\Validation\ValidationException;
class PasswordController extends Controller
{
    public function forgot(Request $r)
    {
        $v = $r->validate(["email" => "required|email|max:254"]);
        // Neither unknown accounts nor throttled resends reveal registration.
        // A failed mail transport must never look like successful delivery.
        try {
            $status = Password::sendResetLink(["email" => Str::lower(trim($v["email"]))]);
        } catch (\Throwable $e) {
            abort(503);
        }
        abort_unless(
            in_array(
                $status,
                [Password::RESET_LINK_SENT, Password::INVALID_USER, Password::RESET_THROTTLED],
                true
            ),
            503
        );
        return $this->ok(["message" => "Jika email terdaftar, instruksi pemulihan akan dikirim."]);
    }
    public function reset(Request $r)
    {
        $v = $r->validate([
            "email" => "required|email|max:254",
            "token" => "required|string|max:256",
            "password" => ["required", "confirmed", PasswordRule::min(12)]
        ]);
        $v["email"] = Str::lower(trim($v["email"]));
        $status = Password::reset($v, function (User $user, string $password) {
            $user
                ->forceFill(["password" => $password, "remember_token" => Str::random(60)])
                ->save();
            $user->tokens()->delete();
            event(new PasswordReset($user));
        });
        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages([
                "token" => ["Tautan tidak valid atau kedaluwarsa. Minta tautan baru."]
            ]);
        }
        return $r->is("api/*")
            ? $this->ok(["message" => "Kata sandi diperbarui. Silakan masuk kembali."])
            : response()
                ->view("password-reset", ["completed" => true])
                ->header("Cache-Control", "no-store");
    }
}
