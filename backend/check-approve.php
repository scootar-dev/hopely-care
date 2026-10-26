<?php
require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
function call($kernel, string $m, string $u, array $d = [], ?string $t = null): array {
    $h = ['HTTP_ACCEPT' => 'application/json', 'HTTP_X_DEBUG_TRACE' => '1'];
    if ($t) { $h['HTTP_AUTHORIZATION'] = 'Bearer '.$t; }
    $req = Illuminate\Http\Request::create("/api/$u", $m, $d, [], [], $h);
    $res = $kernel->handle($req);
    $kernel->terminate($req, $res);
    return [$res->getStatusCode(), json_decode($res->getContent(), true), $res->headers->get('X-Debug-Exception')];
}
[, $adm] = call($kernel, 'POST', 'admin/auth/login', ['email' => 'admin@hopely.care', 'password' => 'HopelyAdmin123!']);
$tokAdm = $adm['data']['token'];
[, $q] = call($kernel, 'GET', 'community/moderation', [], $tokAdm);
$pItem = collect($q['data']['items'] ?? [])->first(fn($i) => $i['id'] === ($argv[1] ?? $i['id']));
if (!$pItem) { echo "no pending\n"; exit; }
echo "Post: {$pItem['id']} rev {$pItem['revision']} status {$pItem['moderation_status']}\n";
[$code, $res, $dbg] = call($kernel, 'POST', "community/moderation/post/{$pItem['id']}", ['action' => 'approve', 'revision' => $pItem['revision'], 'note' => 'Konten sesuai aturan'], $tokAdm);
echo "approve => HTTP $code\n";
echo "exception: ".($dbg ?? '(tidak ada)')."\n";
