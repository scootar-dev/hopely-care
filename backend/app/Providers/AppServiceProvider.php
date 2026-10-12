<?php
namespace App\Providers;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\{Gate, RateLimiter};
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Gate::policy(\App\Models\OwnedRecord::class, \App\Policies\OwnedRecordPolicy::class);
        Gate::policy(\App\Models\Community::class, \App\Policies\CommunityPolicy::class);
        Gate::policy(\App\Models\CommunityPost::class, \App\Policies\CommunityPostPolicy::class);
        Gate::policy(
            \App\Models\CommunityComment::class,
            \App\Policies\CommunityCommentPolicy::class
        );
        RateLimiter::for(
            "community",
            fn(Request $r) => Limit::perMinute(20)->by($r->user()?->id ?? $r->ip())
        );
        RateLimiter::for("auth", fn(Request $r) => Limit::perMinute(8)->by($r->ip()));
        RateLimiter::for(
            "api",
            fn(Request $r) => Limit::perMinute(120)->by($r->user()?->id ?? $r->ip())
        );
        RateLimiter::for(
            "ai",
            fn(Request $r) => Limit::perMinute(12)->by($r->user()?->id ?? $r->ip())
        );
    }
}
