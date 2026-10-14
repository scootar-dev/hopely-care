<?php
namespace Tests\Feature;
use App\Models\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\{Hash, Notification, Password};
use Tests\TestCase;
class PasswordResetTest extends TestCase
{
    use RefreshDatabase;
    private function account(): User
    {
        $u = new User();
        $u->forceFill([
            "name" => "Synthetic reset",
            "email" => "reset@test.invalid",
            "password" => "old-password-123",
            "role" => "PATIENT"
        ])->save();
        return $u;
    }
    public function test_email_reset_is_generic_and_uses_configured_origin(): void
    {
        Notification::fake();
        $u = $this->account();
        config(["app.url" => "https://hopely.test"]);
        $known = $this->postJson("/api/auth/forgot-password", [
            "email" => "RESET@test.invalid"
        ])->assertOk();
        $unknown = $this->postJson("/api/auth/forgot-password", [
            "email" => "absent@test.invalid"
        ])->assertOk();
        $this->assertSame($known->json(), $unknown->json());
        Notification::assertSentTo($u, ResetPassword::class, function ($notification) use ($u) {
            $this->assertStringStartsWith(
                "https://hopely.test/reset-password/",
                $notification->toMail($u)->actionUrl
            );
            return true;
        });
    }
    public function test_reset_is_single_use_and_revokes_existing_sessions(): void
    {
        $u = $this->account();
        $u->createToken("old-session");
        $token = Password::createToken($u);
        $data = [
            "email" => $u->email,
            "token" => $token,
            "password" => "new-password-456",
            "password_confirmation" => "new-password-456"
        ];
        $this->postJson("/api/auth/reset-password", $data)->assertOk();
        $this->assertTrue(Hash::check("new-password-456", $u->fresh()->password));
        $this->assertSame(0, $u->tokens()->count());
        $this->postJson("/api/auth/reset-password", $data)->assertUnprocessable();
        $this->postJson("/api/auth/login", [
            "email" => $u->email,
            "password" => "new-password-456"
        ])->assertOk();
    }
    public function test_expired_or_wrong_account_token_cannot_reset_password(): void
    {
        $u = $this->account();
        $token = Password::createToken($u);
        $data = [
            "email" => "someone@test.invalid",
            "token" => $token,
            "password" => "new-password-456",
            "password_confirmation" => "new-password-456"
        ];
        $this->postJson("/api/auth/reset-password", $data)->assertUnprocessable();
        $this->travel(16)->minutes();
        $data["email"] = $u->email;
        $this->postJson("/api/auth/reset-password", $data)->assertUnprocessable();
        $this->assertTrue(Hash::check("old-password-123", $u->fresh()->password));
    }
    public function test_reset_page_does_not_cache_tokens_and_mail_failure_is_not_success(): void
    {
        $u = $this->account();
        $token = Password::createToken($u);
        $this->get("/reset-password/" . $token . "?email=reset%40test.invalid")
            ->assertOk()
            ->assertSee("Atur ulang kata sandi")
            ->assertHeader("Referrer-Policy", "no-referrer");
        Password::shouldReceive("sendResetLink")
            ->once()
            ->andThrow(new \RuntimeException("private transport detail"));
        $this->postJson("/api/auth/forgot-password", ["email" => $u->email])
            ->assertStatus(503)
            ->assertDontSee("private transport detail");
    }
}
