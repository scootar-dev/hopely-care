<?php
namespace Tests\Feature;
use App\Models\{User, SupportActivity, ActivityRecommendation};
use App\Services\ConsentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
class CompletionRegressionTest extends TestCase
{
    use RefreshDatabase;
    private function user(string $role): User
    {
        $u = new User();
        $u->forceFill(['name' => 'Synthetic', 'email' => uniqid().'@test.invalid', 'password' => 'synthetic-password', 'role' => $role])->save();
        return $u;
    }
    public function test_global_moderator_can_review_but_not_publish_activities(): void
    {
        Sanctum::actingAs($this->user('COMMUNITY_MODERATOR'));
        $this->getJson('/api/community/moderation')->assertOk();
        $this->postJson('/api/admin/activities', [])->assertForbidden();
    }
    public function test_caregiver_can_edit_only_own_name(): void
    {
        $owner = $this->user('CAREGIVER');
        $other = $this->user('CAREGIVER');
        Sanctum::actingAs($owner);
        $this->putJson('/api/me', ['name' => 'Changed', 'user_id' => $other->id])->assertOk();
        $this->assertSame('Changed', $owner->fresh()->name);
        $this->assertSame('Synthetic', $other->fresh()->name);
    }
    public function test_activity_reminder_ownership_and_scheduler_deduplication(): void
    {
        $owner = $this->user('PATIENT');
        $other = $this->user('PATIENT');
        foreach ([$owner, $other] as $u) app(ConsentService::class)->set($u->id, 'HEALTH_DATA_PROCESSING', true);
        $activity = SupportActivity::create(['title' => 'Synthetic', 'description' => 'Test', 'category' => 'relaxation', 'duration_minutes' => 2, 'steps' => ['Rest'], 'suitability_tags' => [], 'active' => true]);
        $row = new ActivityRecommendation();
        $row->forceFill(['user_id' => $owner->id, 'support_activity_id' => $activity->id, 'reason' => 'Test', 'generated_at' => now()])->save();
        Sanctum::actingAs($other);
        $this->putJson('/api/activities/'.$row->id.'/reminder', ['remind_at' => now()->addMinutes(10)->toISOString()])->assertNotFound();
        Sanctum::actingAs($owner);
        $this->putJson('/api/activities/'.$row->id.'/reminder', ['remind_at' => now()->subMinute()->toISOString()])->assertUnprocessable();
        $this->putJson('/api/activities/'.$row->id.'/reminder', ['remind_at' => now()->addMinutes(10)->toISOString()])->assertOk();
        $this->travel(11)->minutes();
        $this->artisan('hopely:reminders')->assertSuccessful();
        $this->artisan('hopely:reminders')->assertSuccessful();
        $this->assertSame(1, \App\Models\CareNotification::where('notification_type', 'activity_reminder')->count());
    }
}
