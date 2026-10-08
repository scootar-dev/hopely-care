<?php
namespace App\Services;
use Illuminate\Support\Facades\Http;
class AiClient
{
    public function post(string $path, array $payload): array
    {
        abort_unless(config("services.ai.key"), 503);
        try {
            $r = Http::timeout(45)
                ->connectTimeout(5)
                ->withHeaders(["X-Internal-Service-Key" => config("services.ai.key")])
                ->post(rtrim(config("services.ai.url"), "/") . $path, $payload);
        } catch (\Throwable $e) {
            abort(503);
        }
        abort_unless($r->successful() && is_array($r->json()), 503);
        return $r->json();
    }
}
