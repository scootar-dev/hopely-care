<?php
namespace Tests\Feature;

use App\Models\{CaregiverLink, CaregiverPermission, User};
use App\Services\ConsentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CaregiverInvitationTest extends TestCase
{
    use RefreshDatabase;

    private function user(string $role): User
    {
        $user = new User();
        $user->forceFill([
            "name" => "Synthetic invitation test",
            "email" => bin2hex(random_bytes(8)) . "@test.invalid",
            "password" => bin2hex(random_bytes(16)),
            "role" => $role,
        ])->save();
        if ($role === "PATIENT") {
            app(ConsentService::class)->set($user->id, "HEALTH_DATA_PROCESSING", true);
        }
        return $user;
    }

    public function test_invite_accept_once_and_revoke_preserves_private_defaults(): void
    {
        $patient = $this->user("PATIENT");
        $caregiver = $this->user("CAREGIVER");
        $stranger = $this->user("CAREGIVER");
        Sanctum::actingAs($patient);
        $invitation = $this->postJson("/api/caregivers/invite", [
            "email" => $caregiver->email,
            "relationship_label" => "Keluarga",
        ])->assertCreated()->json("data");
        $link = CaregiverLink::findOrFail($invitation["id"]);
        $this->assertSame($patient->id, $link->patient_user_id);
        $this->assertSame($caregiver->email, $link->invited_email);
        $permissions = CaregiverPermission::where("caregiver_link_id", $link->id)->firstOrFail();
        $this->assertFalse($permissions->can_view_wellbeing_summary);
        $this->assertFalse($permissions->can_receive_support_alert);
        Sanctum::actingAs($stranger);
        $this->postJson("/api/caregivers/accept", ["token" => $invitation["invitation_token"]])
            ->assertNotFound();
        Sanctum::actingAs($caregiver);
        $this->postJson("/api/caregivers/accept", ["token" => $invitation["invitation_token"]])
            ->assertOk();
        $this->postJson("/api/caregivers/accept", ["token" => $invitation["invitation_token"]])
            ->assertNotFound();
        $this->getJson("/api/caregiver/patients")->assertJsonPath("data.0.patient_id", $patient->id);
        $this->getJson("/api/caregiver/patients/{$patient->id}/summary")->assertForbidden();
        Sanctum::actingAs($patient);
        $this->deleteJson("/api/caregivers/{$link->id}")->assertOk();
        Sanctum::actingAs($caregiver);
        $this->getJson("/api/caregiver/patients")->assertJsonCount(0, "data");
    }

    public function test_patient_accounts_cannot_be_invited_as_caregivers(): void
    {
        $patient = $this->user("PATIENT");
        $other = $this->user("PATIENT");
        Sanctum::actingAs($patient);
        foreach ([$patient->email, $other->email] as $email) {
            $this->postJson("/api/caregivers/invite", [
                "email" => $email,
                "relationship_label" => "Keluarga",
            ])->assertUnprocessable()->assertJsonValidationErrors("email");
        }
        $this->assertDatabaseCount("caregiver_links", 0);
    }

    public function test_invitation_may_be_created_before_caregiver_registers(): void
    {
        Sanctum::actingAs($this->user("PATIENT"));
        $this->postJson("/api/caregivers/invite", [
            "email" => "future-caregiver@test.invalid",
            "relationship_label" => "Keluarga",
        ])->assertCreated();
    }
}
