<?php
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__ . "/../routes/api.php",
        commands: __DIR__ . "/../routes/console.php",
        health: "/up",
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            "role" => App\Http\Middleware\RequireRole::class,
            "health.consent" => App\Http\Middleware\RequireHealthConsent::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(fn(Request $request, Throwable $e) => true);
        $exceptions->render(function (Illuminate\Validation\ValidationException $e, Request $r) {
            return response()->json(
                [
                    "success" => false,
                    "message" => "Periksa kembali isian.",
                    "errors" => $e->errors(),
                ],
                422,
            );
        });
        // Do not include exception messages, stack traces, request bodies or provider payloads.
        $exceptions->render(function (Throwable $e, Request $r) {
            $status =
                $e instanceof Symfony\Component\HttpKernel\Exception\HttpExceptionInterface
                    ? $e->getStatusCode()
                    : ($e instanceof Illuminate\Auth\AuthenticationException
                        ? 401
                        : ($e instanceof Illuminate\Auth\Access\AuthorizationException
                            ? 403
                            : ($e instanceof Illuminate\Database\Eloquent\ModelNotFoundException
                                ? 404
                                : 500)));
            return response()->json(
                [
                    "success" => false,
                    "message" => match ($status) {
                        401 => "Silakan masuk kembali.",
                        403 => "Akses atau persetujuan belum tersedia.",
                        404 => "Data tidak ditemukan.",
                        409 => "Persetujuan berubah. Silakan coba lagi.",
                        429 => "Terlalu banyak permintaan. Coba sebentar lagi.",
                        503 => "Layanan belum tersedia. Silakan coba lagi.",
                        default => "Permintaan tidak dapat diproses.",
                    },
                ],
                $status,
            );
        });
        $exceptions->report(function (Throwable $e) {
            return false;
        });
    })
    ->create();
