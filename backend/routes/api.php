<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{
    AuthController,
    ConsentController,
    RecordController,
    AiController,
    CaregiverController,
    NotificationController,
    AdminController,
    ProfilePhotoController
};
Route::middleware("throttle:auth")->group(function () {
    Route::post('admin/auth/login', [\App\Http\Controllers\AdminWorkspaceController::class, 'login']);
    Route::post("auth/register", [AuthController::class, "register"]);
    Route::post("auth/login", [AuthController::class, "login"]);
    Route::post("auth/forgot-password", [
        \App\Http\Controllers\PasswordController::class,
        "forgot"
    ]);
    Route::post("auth/reset-password", [\App\Http\Controllers\PasswordController::class, "reset"]);
});
Route::middleware(["auth:sanctum", "throttle:api"])->group(function () {
    require __DIR__ . "/community.php";
    Route::get("me", [AuthController::class, "me"]);
    Route::put('me', [AuthController::class, 'account']);
    Route::get('admin/workspace/{module}', [\App\Http\Controllers\AdminWorkspaceController::class, 'index'])
        ->middleware('role:ADMIN,SUPER_ADMIN,CONTENT_ADMIN,COMMUNITY_MODERATOR');
    Route::middleware('role:PATIENT')->group(function () {
        Route::post('support-alerts', [\App\Http\Controllers\SupportAlertController::class, 'store'])->middleware('throttle:3,1');
        Route::get('support-alerts/active', [\App\Http\Controllers\SupportAlertController::class, 'active']);
    });
    Route::get('caregiver/support-alerts', [\App\Http\Controllers\SupportAlertController::class, 'active'])->middleware('role:CAREGIVER');
    foreach (['acknowledge', 'resolve', 'cancel'] as $action) {
        Route::post("support-alerts/{id}/$action", [\App\Http\Controllers\SupportAlertController::class, 'transition'])->defaults('action', $action);
    }
    Route::get("me/avatar", [ProfilePhotoController::class, "show"]);
    Route::post("me/avatar", [ProfilePhotoController::class, "store"]);
    Route::delete("me/avatar", [ProfilePhotoController::class, "destroy"]);
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
        Route::get("journals/{id}/reflection", [AiController::class, "journalReflection"]);
        foreach (["checkins", "symptoms", "treatments", "journals"] as $kind) {
            foreach (
                [
                    ["get", "", "index"],
                    ["post", "", "store"],
                    ["get", "/{id}", "show"],
                    ["put", "/{id}", "update"],
                    ["delete", "/{id}", "destroy"]
                ]
                as [$verb, $suffix, $action]
            ) {
                Route::$verb($kind . $suffix, [RecordController::class, $action])->defaults(
                    "kind",
                    $kind
                );
            }
        }
        Route::get("activities", [AiController::class, "activities"]);
        Route::get('knowledge/articles', [\App\Http\Controllers\KnowledgeArticleController::class, 'index']);
        Route::get('knowledge/articles/{id}', [\App\Http\Controllers\KnowledgeArticleController::class, 'show']);
        Route::post("activities/{id}/complete", [AiController::class, "complete"]);
        Route::put('activities/{id}/reminder', [AiController::class, 'reminder']);
        Route::get("chat/sessions", [AiController::class, "sessions"]);
        Route::get("chat/sessions/{id}/messages", [AiController::class, "messages"]);
        Route::middleware("throttle:ai")->group(function () {
            Route::post("journals/{id}/analyze", [AiController::class, "analyzeJournal"]);
            Route::post("checkins/{id}/analyze", [AiController::class, "analyzeCheckin"]);
            Route::post("ai/chat", [AiController::class, "chat"]);
            Route::get("insights", [AiController::class, "insights"]);
            Route::get("activities/recommended", [AiController::class, "recommended"]);
            Route::post("doctor-summary", [AiController::class, "summary"]);
            Route::get("doctor-summary", [AiController::class, "summaries"]);
            Route::get("doctor-summary/{id}", [AiController::class, "savedSummary"]);
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
            "coach"
        ])->middleware("throttle:ai");
    });
    Route::middleware("role:ADMIN,SUPER_ADMIN,CONTENT_ADMIN")->group(function () {
        Route::get('admin/knowledge/documents', [\App\Http\Controllers\KnowledgeManagementController::class, 'index']);
        Route::post('admin/knowledge/documents', [\App\Http\Controllers\KnowledgeManagementController::class, 'save']);
        Route::put('admin/knowledge/documents/{id}', [\App\Http\Controllers\KnowledgeManagementController::class, 'save']);
        Route::post('admin/knowledge/documents/{id}/{action}', [\App\Http\Controllers\KnowledgeManagementController::class, 'transition']);
        // Legacy callers now create a draft; publication requires independent review.
        Route::post("admin/knowledge/ingest", [\App\Http\Controllers\KnowledgeManagementController::class, "save"]);
        Route::post("admin/activities", [AdminController::class, "activity"]);
        Route::put("admin/activities/{id}", [AdminController::class, "activity"]);
    });
    Route::middleware('role:ADMIN,SUPER_ADMIN')->group(function () {
        Route::post('admin/communities', [\App\Http\Controllers\AdminCommunityController::class, 'save']);
        Route::put('admin/communities/{id}', [\App\Http\Controllers\AdminCommunityController::class, 'save']);
    });
});
