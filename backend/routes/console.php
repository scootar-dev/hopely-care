<?php
use Illuminate\Support\Facades\{Artisan, Schedule};
use App\Models\{Treatment, PatientProfile, DailyCheckin};
use App\Services\{NotificationService, ConsentService};
Artisan::command("hopely:reminders", function () {
    $n = app(NotificationService::class);
    $c = app(ConsentService::class);
    foreach (
        Treatment::where("status", "scheduled")
            ->whereBetween("scheduled_at", [now(), now()->addDay()])
            ->get()
        as $t
    ) {
        if ($c->active($t->user_id, "HEALTH_DATA_PROCESSING")) {
            $n->send(
                $t->user_id,
                "treatment_reminder",
                "treatment:" . $t->id . ":" . $t->scheduled_at,
            );
        }
    }
    foreach (PatientProfile::cursor() as $p) {
        $local = now($p->timezone);
        if (
            $local->hour === 19 &&
            $c->active($p->user_id, "HEALTH_DATA_PROCESSING") &&
            !DailyCheckin::where("user_id", $p->user_id)
                ->where("checkin_date", $local->toDateString())
                ->exists()
        ) {
            $n->send(
                $p->user_id,
                "daily_checkin",
                "daily:" . $p->user_id . ":" . $local->toDateString(),
            );
        }
    }
});
Schedule::command("hopely:reminders")->everyFifteenMinutes()->withoutOverlapping();
Schedule::command("sanctum:prune-expired --hours=24")->daily();

Artisan::command("hopely:create-admin", function () {
    $email = env("ADMIN_EMAIL");
    $password = env("ADMIN_PASSWORD");
    $name = env("ADMIN_NAME", "Administrator");
    if (
        !filter_var($email, FILTER_VALIDATE_EMAIL) ||
        !is_string($password) ||
        strlen($password) < 16
    ) {
        $this->error(
            "Set ADMIN_EMAIL and ADMIN_PASSWORD (at least 16 characters) in the operator environment.",
        );
        return 1;
    }
    if (\App\Models\User::where("email", strtolower($email))->exists()) {
        $this->error(
            "Account already exists. Existing roles and passwords are never overwritten by this command.",
        );
        return 1;
    }
    $user = new \App\Models\User();
    $user
        ->forceFill([
            "name" => $name,
            "email" => strtolower($email),
            "password" => $password,
            "role" => "ADMIN",
        ])
        ->save();
    $this->info("Administrator account created. No credentials are printed.");
    return 0;
});
