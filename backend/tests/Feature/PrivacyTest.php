<?php
namespace Tests\Feature;
use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use App\Models\{User, Journal, DailyCheckin, CaregiverLink, CaregiverPermission};
use App\Services\ConsentService;
use Laravel\Sanctum\Sanctum;
class PrivacyTest extends TestCase
{
    use RefreshDatabase;
    private function user(string $role = "PATIENT"): User
    {
        $u = new User();
        $u->forceFill([
            "name" => "Synthetic Test",
            "email" => bin2hex(random_bytes(8)) . "@test.invalid",
            "password" => bin2hex(random_bytes(16)),
            "role" => $role,
        ])->save();
        return $u;
    }
    private function consent(
        User $u,
        string $type = "HEALTH_DATA_PROCESSING",
        bool $accept = true,
    ): void {
        app(ConsentService::class)->set($u->id, $type, $accept);
    }
    public function test_anonymous_patient_endpoint_is_denied(): void
    {
        $this->getJson("/api/journals")->assertUnauthorized();
    }
    public function test_users_cannot_register_as_admin(): void
    {
        $this->postJson("/api/auth/register", [
            "name" => "x",
            "email" => "x@test.invalid",
            "password" => bin2hex(random_bytes(20)),
            "role" => "ADMIN",
        ])->assertUnprocessable();
    }
    public function test_patient_cannot_read_another_journal(): void
    {
        $a = $this->user();
        $b = $this->user();
        $this->consent($b);
        $j = new Journal();
        $j->forceFill([
            "user_id" => $a->id,
            "content" => "private",
            "journal_date" => today()->toDateString(),
        ])->save();
        Sanctum::actingAs($b);
        $this->getJson("/api/journals/" . $j->id)->assertForbidden();
    }
    public function test_health_consent_is_required(): void
    {
        $u = $this->user();
        Sanctum::actingAs($u);
        $this->getJson("/api/checkins")->assertForbidden();
    }
    public function test_scores_outside_scale_are_rejected(): void
    {
        $u = $this->user();
        $this->consent($u);
        Sanctum::actingAs($u);
        $this->postJson("/api/checkins", [
            "checkin_date" => today()->toDateString(),
            "mood_score" => 6,
            "anxiety_score" => 2,
            "energy_score" => 2,
            "sleep_score" => 2,
            "pain_score" => 2,
        ])->assertUnprocessable();
    }
    public function test_checkin_is_unique_per_patient_date(): void
    {
        $u = $this->user();
        $this->consent($u);
        Sanctum::actingAs($u);
        $data = [
            "checkin_date" => today()->toDateString(),
            "mood_score" => 2,
            "anxiety_score" => 4,
            "energy_score" => 2,
            "sleep_score" => 2,
            "pain_score" => 3,
        ];
        $this->postJson("/api/checkins", $data)->assertCreated();
        $this->postJson("/api/checkins", $data)->assertUnprocessable();
    }
    public function test_journal_analysis_requires_both_consents(): void
    {
        Http::preventStrayRequests();
        $u = $this->user();
        $this->consent($u);
        Sanctum::actingAs($u);
        $j = new Journal();
        $j->forceFill([
            "user_id" => $u->id,
            "content" => "private",
            "journal_date" => today()->toDateString(),
            "ai_analysis_allowed" => true,
        ])->save();
        $this->postJson("/api/journals/" . $j->id . "/analyze")->assertForbidden();
        $this->consent($u, "AI_JOURNAL_ANALYSIS");
        $j->ai_analysis_allowed = false;
        $j->save();
        $this->postJson("/api/journals/" . $j->id . "/analyze")->assertForbidden();
        Http::assertNothingSent();
    }
    public function test_caregiver_sees_only_permitted_aggregates(): void
    {
        $p = $this->user();
        $c = $this->user("CAREGIVER");
        $this->consent($p);
        $this->consent($p, "CAREGIVER_WELLBEING_SHARE");
        $link = new CaregiverLink();
        $link
            ->forceFill([
                "patient_user_id" => $p->id,
                "caregiver_user_id" => $c->id,
                "invited_email" => $c->email,
                "relationship_label" => "family",
                "invitation_status" => "accepted",
            ])
            ->save();
        $perm = new CaregiverPermission();
        $perm->forceFill(["caregiver_link_id" => $link->id])->save();
        Sanctum::actingAs($c);
        $this->getJson("/api/caregiver/patients/" . $p->id . "/summary")
            ->assertOk()
            ->assertJsonMissingPath("data.wellbeing_summary")
            ->assertJsonMissingPath("data.journals")
            ->assertJsonMissingPath("data.chat");
        $perm->can_view_wellbeing_summary = true;
        $perm->save();
        $this->getJson("/api/caregiver/patients/" . $p->id . "/summary")
            ->assertOk()
            ->assertJsonPath("data.wellbeing_summary.recorded_days", 0)
            ->assertJsonMissingPath("data.treatment_schedule");
        $this->consent($p, "CAREGIVER_WELLBEING_SHARE", false);
        $this->getJson("/api/caregiver/patients/" . $p->id . "/summary")->assertForbidden();
    }
    public function test_unlinked_caregiver_is_denied(): void
    {
        $p = $this->user();
        $c = $this->user("CAREGIVER");
        Sanctum::actingAs($c);
        $this->getJson("/api/caregiver/patients/" . $p->id . "/summary")->assertNotFound();
    }
    public function test_revocation_clears_derived_emotion_signal(): void
    {
        $p = $this->user();
        $this->consent($p);
        $c = new DailyCheckin();
        $c->forceFill([
            "user_id" => $p->id,
            "checkin_date" => today()->toDateString(),
            "mood_score" => 2,
            "anxiety_score" => 4,
            "energy_score" => 2,
            "sleep_score" => 2,
            "pain_score" => 3,
            "emotion_signal" => ["scores" => ["fear" => 0.8]],
        ])->save();
        $this->consent($p, "AI_JOURNAL_ANALYSIS", false);
        $this->assertNull($c->fresh()->emotion_signal);
    }
}
