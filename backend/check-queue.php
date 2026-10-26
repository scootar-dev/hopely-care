<?php
require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
function call($kernel, string $m, string $u, array $d = [], ?string $t = null): array {
    $h = ['HTTP_ACCEPT' => 'application/json'];
    if ($t) { $h['HTTP_AUTHORIZATION'] = 'Bearer '.$t; }
    $req = Illuminate\Http\Request::create("/api/$u", $m, $d, [], [], $h);
    $res = $kernel->handle($req);
    $kernel->terminate($req, $res);
    return [$res->getStatusCode(), json_decode($res->getContent(), true)];
}
[, $adm] = call($kernel, 'POST', 'admin/auth/login', ['email' => 'admin@hopely.care', 'password' => 'HopelyAdmin123!']);
[, $q] = call($kernel, 'GET', 'community/moderation', [], $adm['data']['token']);
echo json_encode($q, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
