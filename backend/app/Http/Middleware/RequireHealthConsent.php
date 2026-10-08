<?php
namespace App\Http\Middleware;
use Closure;
use Illuminate\Http\Request;
use App\Services\ConsentService;
class RequireHealthConsent
{
    public function handle(Request $r, Closure $next)
    {
        abort_unless(
            app(ConsentService::class)->active($r->user()->id, "HEALTH_DATA_PROCESSING"),
            403,
        );
        return $next($r);
    }
}
