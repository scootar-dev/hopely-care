<?php
namespace App\Services;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
class AiClient
{
    public function post(string $path, array $payload, int $timeout = 45): array
    {
        abort_unless(config("services.ai.key"), 503);
        try {
            $r = Http::timeout($timeout)
                ->connectTimeout(5)
                ->withHeaders(["X-Internal-Service-Key" => config("services.ai.key")])
                ->post(rtrim(config("services.ai.url"), "/") . $path, $payload);
        } catch (\Throwable $e) {
            Log::warning("AI service connection failed", [
                "path" => $path,
                "exception" => get_class($e)
            ]);
            abort(503);
        }
        if (!$r->successful() || !is_array($r->json())) {
            Log::warning("AI service returned an invalid response", [
                "path" => $path,
                "status" => $r->status(),
                "error_code" => is_array($r->json()) ? data_get($r->json(), "error.code") : null
            ]);
            abort(503);
        }
        return $r->json();
    }
}
