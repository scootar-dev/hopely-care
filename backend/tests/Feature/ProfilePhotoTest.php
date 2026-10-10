<?php
namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfilePhotoTest extends TestCase
{
    use RefreshDatabase;

    private const PNG = "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGPUCj/GwMDAxMDAwMDAAAAO4gFLKvoKdQAAAABJRU5ErkJggg==";

    private function user(string $role = "PATIENT"): User
    {
        $user = new User();
        $user->forceFill([
            "name" => "Synthetic photo test",
            "email" => bin2hex(random_bytes(8)) . "@test.invalid",
            "password" => "synthetic-photo-password",
            "role" => $role,
        ])->save();
        return $user;
    }

    private function photo(): UploadedFile
    {
        return UploadedFile::fake()->createWithContent("profile.png", base64_decode(self::PNG));
    }

    public function test_profile_photos_require_authentication(): void
    {
        $this->getJson("/api/me/avatar")->assertUnauthorized();
        $this->postJson("/api/me/avatar")->assertUnauthorized();
        $this->deleteJson("/api/me/avatar")->assertUnauthorized();
    }

    public function test_upload_is_encrypted_private_and_cannot_target_another_user(): void
    {
        Storage::fake("local");
        $owner = $this->user();
        $other = $this->user();
        Sanctum::actingAs($owner);
        $this->post("/api/me/avatar", ["photo" => $this->photo(), "user_id" => $other->id])
            ->assertOk()
            ->assertJsonPath("data.mime_type", "image/png")
            ->assertJsonPath("data.base64", self::PNG);
        $path = "profile-photos/{$owner->id}.enc";
        Storage::disk("local")->assertExists($path);
        $this->assertStringNotContainsString(self::PNG, Storage::disk("local")->get($path));
        $response = $this->getJson("/api/me/avatar?user_id={$other->id}")
            ->assertOk()->assertJsonPath("data.base64", self::PNG);
        $this->assertStringContainsString("no-store", $response->headers->get("Cache-Control"));
        Sanctum::actingAs($other);
        $this->getJson("/api/me/avatar?user_id={$owner->id}")->assertOk()->assertJsonPath("data", null);
        $this->deleteJson("/api/me/avatar", ["user_id" => $owner->id])->assertOk();
        Storage::disk("local")->assertExists($path);
    }

    public function test_caregiver_can_replace_and_remove_own_photo_without_health_consent(): void
    {
        Storage::fake("local");
        $user = $this->user("CAREGIVER");
        Sanctum::actingAs($user);
        $this->getJson("/api/me/avatar")->assertOk()->assertJsonPath("data", null);
        $this->post("/api/me/avatar", ["photo" => $this->photo()])->assertOk();
        $path = "profile-photos/{$user->id}.enc";
        $previous = Storage::disk("local")->get($path);
        $this->post("/api/me/avatar", ["photo" => $this->photo()])->assertOk();
        $this->assertNotSame($previous, Storage::disk("local")->get($path));
        $this->assertCount(1, Storage::disk("local")->allFiles("profile-photos"));
        $this->deleteJson("/api/me/avatar")->assertOk();
        Storage::disk("local")->assertMissing($path);
        $this->getJson("/api/me/avatar")->assertOk()->assertJsonPath("data", null);
    }

    public function test_invalid_or_oversized_upload_preserves_existing_photo(): void
    {
        Storage::fake("local");
        Sanctum::actingAs($this->user());
        $this->post("/api/me/avatar", ["photo" => $this->photo()])->assertOk();
        $this->post("/api/me/avatar", [
            "photo" => UploadedFile::fake()->createWithContent("fake.png", "not an image"),
        ])->assertUnprocessable();
        $this->post("/api/me/avatar", [
            "photo" => UploadedFile::fake()->create("large.png", 2049, "image/png"),
        ])->assertUnprocessable();
        $this->getJson("/api/me/avatar")->assertOk()->assertJsonPath("data.base64", self::PNG);
    }

    public function test_deleting_account_also_deletes_photo(): void
    {
        Storage::fake("local");
        $user = $this->user();
        Sanctum::actingAs($user);
        $this->post("/api/me/avatar", ["photo" => $this->photo()])->assertOk();
        $this->deleteJson("/api/me", ["password" => "synthetic-photo-password"])->assertOk();
        Storage::disk("local")->assertMissing("profile-photos/{$user->id}.enc");
        $this->assertDatabaseMissing("users", ["id" => $user->id]);
    }
}
