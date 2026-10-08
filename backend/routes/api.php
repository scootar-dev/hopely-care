<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{
    AuthController,
    ConsentController,
    RecordController,
    AiController,
    CaregiverController,
    NotificationController,
    AdminController
};
Route::middleware("throttle:auth")->group(function () {
    Route::post("auth/register", [AuthController::class, "register"]);
    Route::post("auth/login", [AuthController::class, "login"]);
});
Route::middleware(["auth:sanctum", "throttle:api"])->group(function () {
    Route::get("me", [AuthController::class, "me"]);
    Route::post("auth/logout", [AuthController::class, "logout"]);
    Route::delete("me", [AuthController::class, "destroy"]);
    Route::get("consents", [ConsentController::class, "index"]);
    Route::put("consents", [ConsentController::class, "update"]);
    Route::get("notifications", [NotificationController::class, "index"]);
    Route::put("notifications/{id}/read", [NotificationController::class, "read"]);
    Route::post("devices", [NotificationController::class, "device"]);
    Route::delete("devices/{id}", [NotificationController::class, "removeDevice"]);
    Route::middleware(["role:PATIENT", "health.consent"])->group(function () {
        Route::put("profile", [AuthController::class, "profile"]);
        foreach (["checkins", "symptoms", "treatments", "journals"] as $kind) {
            foreach (
                [
                    ["get", "", "index"],
                    ["post", "", "store"],
                    ["get", "/{id}", "show"],
                    ["put", "/{id}", "update"],
                    ["delete", "/{id}", "destroy"],
                ]
                as [$verb, $suffix, $action]
            ) {
                Route::$verb($kind . $suffix, [RecordController::class, $action])->defaults(
                    "kind",
                    $kind,
                );
            }
        }
        Route::get("activities", [AiController::class, "activities"]);
        Route::post("activities/{id}/complete", [AiController::class, "complete"]);
        Route::get("chat/sessions", [AiController::class, "sessions"]);
        Route::get("chat/sessions/{id}/messages", [AiController::class, "messages"]);
        Route::middleware("throttle:ai")->group(function () {
            Route::post("journals/{id}/analyze", [AiController::class, "analyzeJournal"]);
            Route::post("checkins/{id}/analyze", [AiController::class, "analyzeCheckin"]);
            Route::post("ai/chat", [AiController::class, "chat"]);
            Route::get("insights", [AiController::class, "insights"]);
            Route::get("activities/recommended", [AiController::class, "recommended"]);
            Route::post("doctor-summary", [AiController::class, "summary"]);
            Route::post("knowledge/query", [AiController::class, "knowledge"]);
        });
        Route::post("caregivers/invite", [CaregiverController::class, "invite"]);
        Route::get("caregivers", [CaregiverController::class, "index"]);
        Route::put("caregivers/{id}/permissions", [CaregiverController::class, "permissions"]);
        Route::delete("caregivers/{id}", [CaregiverController::class, "revoke"]);
    });
    Route::middleware("role:CAREGIVER")->group(function () {
        Route::post("caregivers/accept", [CaregiverController::class, "accept"]);
        Route::get("caregiver/patients", [CaregiverController::class, "patients"]);
        Route::get("caregiver/patients/{id}/summary", [CaregiverController::class, "summary"]);
        Route::post("caregiver/patients/{id}/coach", [
            CaregiverController::class,
            "coach",
        ])->middleware("throttle:ai");
    });
    Route::middleware("role:ADMIN")->group(function () {
        Route::post("admin/knowledge/ingest", [AdminController::class, "ingest"]);
        Route::post("admin/activities", [AdminController::class, "activity"]);
        Route::put("admin/activities/{id}", [AdminController::class, "activity"]);
    });
});
