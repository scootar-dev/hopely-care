<?php
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\PasswordController;
Route::get('/admin', fn () => response()->view('admin')->header('Cache-Control', 'no-store'))->name('admin');
Route::get("/reset-password/{token}", function (Request $request, string $token) {
    return response()
        ->view("password-reset", ["token" => $token, "email" => $request->query("email", "")])
        ->header("Cache-Control", "no-store")
        ->header("Referrer-Policy", "no-referrer");
})->name("password.reset");
Route::post("/reset-password", [PasswordController::class, "reset"])
    ->middleware("throttle:auth")
    ->name("password.update");
