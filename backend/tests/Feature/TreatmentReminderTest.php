<?php
namespace Tests\Feature;

use App\Models\{User, Treatment, CareNotification};
use App\Services\ConsentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TreatmentReminderTest extends TestCase
{
    use RefreshDatabase;

    public function test_due_reminder_uses_utc_is_deduplicated_and_respects_status_and_consent(): void
    {
        $this->travelTo(\Carbon\Carbon::parse('2026-10-17T03:00:00Z'));
        config(['services.firebase.credentials' => null]);
        $user = new User();
        $user->forceFill(['name' => 'Reminder Test', 'email' => 'reminder@test.invalid',
            'password' => 'synthetic-password', 'role' => 'PATIENT'])->save();
        app(ConsentService::class)->set($user->id, 'HEALTH_DATA_PROCESSING', true);
        $make = function ($status, $time) use ($user) {
            $treatment = new Treatment();
            $treatment->forceFill(['user_id' => $user->id, 'title' => 'Private appointment',
                'treatment_type' => 'Consultation', 'scheduled_at' => $time, 'status' => $status])->save();
            return $treatment;
        };
        $due = $make('scheduled', now());
        $make('scheduled', now()->addHours(2));
        $make('cancelled', now());
        $make('completed', now());
        $make('scheduled', now()->addDays(3));
        $this->artisan('hopely:reminders')->assertSuccessful();
        $this->artisan('hopely:reminders')->assertSuccessful();
        $this->assertEquals(1, CareNotification::where('notification_type', 'treatment_due')->count());
        $this->assertEquals(1, CareNotification::where('notification_type', 'treatment_reminder')->count());
        $this->assertStringNotContainsString('Private appointment', CareNotification::first()->body);

        $due->update(['scheduled_at' => now()->addHour()]);
        $this->travel(1)->hours();
        $this->artisan('hopely:reminders')->assertSuccessful();
        $this->assertEquals(2, CareNotification::where('notification_type', 'treatment_due')->count());
        app(ConsentService::class)->set($user->id, 'HEALTH_DATA_PROCESSING', false);
        $make('scheduled', now());
        $before = CareNotification::count();
        $this->artisan('hopely:reminders')->assertSuccessful();
        $this->assertEquals($before, CareNotification::count());
    }
}
