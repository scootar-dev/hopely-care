<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{
    CommunityController,
    CommunityContentController,
    CommunitySafetyController
};

// Included inside the existing Sanctum + API throttle group.
Route::middleware("role:PATIENT,CAREGIVER,ADMIN")->group(function () {
    Route::get("communities", [CommunityController::class, "index"]);
    Route::get("community/home", [CommunityController::class, "home"]);
    Route::get("community/my-communities", [CommunityController::class, "mine"]);
    Route::get("community/preferences", [CommunityController::class, "preferences"]);
    Route::put("community/preferences", [CommunityController::class, "preferences"]);
    Route::get("community/safety", [CommunitySafetyController::class, "index"]);
    Route::get("community/moderation", [CommunitySafetyController::class, "queue"]);
    Route::get("community/feed", [CommunityContentController::class, "index"]);
    Route::get("communities/{community}", [CommunityController::class, "show"]);
    Route::get("communities/{community}/posts", [CommunityContentController::class, "index"]);
    Route::get("community/posts/{post}", [CommunityContentController::class, "show"]);
    Route::get("community/posts/{post}/image", [CommunityContentController::class, "image"]);
    Route::get("community/posts/{post}/comments", [CommunityContentController::class, "comments"]);
    Route::middleware("throttle:community")->group(function () {
        Route::post("communities/{community}/join", [CommunityController::class, "join"]);
        Route::delete("communities/{community}/leave", [CommunityController::class, "leave"]);
        Route::post("communities/{community}/posts", [CommunityContentController::class, "store"]);
        Route::put("community/posts/{post}", [CommunityContentController::class, "update"]);
        Route::delete("community/posts/{post}", [CommunityContentController::class, "destroy"]);
        Route::post("community/posts/{post}/reactions", [
            CommunityContentController::class,
            "react"
        ]);
        Route::delete("community/posts/{post}/reactions", [
            CommunityContentController::class,
            "unreact"
        ]);
        Route::post("community/posts/{post}/comments", [
            CommunityContentController::class,
            "comment"
        ]);
        Route::delete("community/comments/{comment}", [
            CommunityContentController::class,
            "deleteComment"
        ]);
        Route::post("community/reports", [CommunitySafetyController::class, "report"]);
        Route::post("users/{user}/block", [CommunitySafetyController::class, "block"]);
        Route::delete("users/{user}/block", [CommunitySafetyController::class, "unblock"]);
        Route::post("community/moderation/{kind}/{id}", [
            CommunitySafetyController::class,
            "review"
        ]);
    });
});
