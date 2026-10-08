<?php
namespace Tests;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
abstract class TestCase extends BaseTestCase
{
    public function createApplication()
    {
        $app = require __DIR__ . "/../bootstrap/app.php";
        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();
        return $app;
    }
    protected function setUp(): void
    {
        parent::setUp();
        config([
            "app.key" => "base64:" . base64_encode(random_bytes(32)),
            "hashing.bcrypt.rounds" => 4,
        ]);
    }
}
