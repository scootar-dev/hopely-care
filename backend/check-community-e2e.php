<?php
require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use App\Models\CommunityContentRequest;
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

function call($kernel, string $method, string $uri, array $data = [], ?string $token = null): array {
    app('auth')->forgetGuards(); // proses panjang: jangan pakai cache guard antar-request
    $headers = ['HTTP_ACCEPT' => 'application/json'];
    if ($token) { $headers['HTTP_AUTHORIZATION'] = 'Bearer '.$token; }
    $req = Illuminate\Http\Request::create("/api/$uri", $method, $data, [], [], $headers);
    $res = $kernel->handle($req);
    $kernel->terminate($req, $res);
    return [$res->getStatusCode(), json_decode($res->getContent(), true)];
}

function step(string $label, array $r) {
    [$code, $body] = $r;
    $summary = $body['message'] ?? $code;
    if (!$body['success']) { echo "$label => FAIL [$code] $summary\n"; exit(1); }
    echo "$label => OK [$code]\n";
    return $body['data'] ?? null;
}

// ---------- Setup: daftar 2 pengguna baru + login admin ----------
$suffix = substr((string) time(), -6);
$pw = 'E2eTestPass2026!';
[, $bodyA] = call($kernel, 'POST', 'auth/register', ['name' => 'E2E A', 'email' => "e2ea$suffix@test.invalid", 'password' => $pw, 'password_confirmation' => $pw, 'role' => 'PATIENT']);
[, $bodyB] = call($kernel, 'POST', 'auth/register', ['name' => 'E2E B', 'email' => "e2eb$suffix@test.invalid", 'password' => $pw, 'password_confirmation' => $pw, 'role' => 'PATIENT']);
[, $bodyAdmin] = call($kernel, 'POST', 'admin/auth/login', ['email' => 'admin@hopely.care', 'password' => 'HopelyAdmin123!']);
$tokA = $bodyA['data']['token']; $tokB = $bodyB['data']['token']; $tokAdm = $bodyAdmin['data']['token'];
echo "Setup: 2 pengguna + admin siap.\n";

// ---------- 1. Admin membuat komunitas ----------
$community = step('1. Admin buat komunitas', call($kernel, 'POST', 'admin/communities', ['name' => 'E2E Komunitas', 'slug' => "e2e-$suffix", 'description' => 'Tes visualisasi', 'category' => 'peer_support', 'is_active' => true], $tokAdm));
$cid = $community['id'];

// ---------- 2. Pengguna A bergabung ----------
step('2. Pengguna A join komunitas', call($kernel, 'POST', "communities/$cid/join", ['rules_accepted' => '1', 'display_name' => 'Sarah A'], $tokA));

// ---------- 3. Pengguna A mengunggah postingan ----------
$resp = call($kernel, 'POST', "communities/$cid/posts", ['content' => 'Halo semuanya, ini unggahan tes dari A.', 'sharing_acknowledged' => '1'], $tokA);
$postData = step('3. Pengguna A upload postingan', $resp);
$pid = $postData['id'];
echo '   Status moderasi awal: '.$postData['moderation_status']."\n";

// Jika di moderation queue (AI service tidak berjalan => admin review manusia)
[$code, $q] = call($kernel, 'GET', 'community/moderation', [], $tokAdm);
echo "   [debug] moderation HTTP $code, items: ".count($q['data']['items'] ?? []).", pid=$pid\n";
$pItem = collect($q['data']['items'] ?? [])->first(fn($i) => $i['id'] === $pid);
if ($pItem && $postData['moderation_status'] !== 'approved') {
    step('3b. Admin setujui postingan (moderasi manusia)', call($kernel, 'POST', "community/moderation/post/$pid", ['action' => 'approve', 'revision' => $pItem['revision'], 'note' => 'Konten sesuai aturan'], $tokAdm));
}

// Pengguna B sebelum join → TIDAK boleh bisa participate/see? (cek dulu)
[$codeB, $resB] = call($kernel, 'GET', "community/posts/$pid", [], $tokB);
echo '4. Cepat cek sebelum join: HTTP '.$codeB."\n";

// ---------- 5. Pengguna B bergabung lalu melihat feed ----------
step('5. Pengguna B join komunitas', call($kernel, 'POST', "communities/$cid/join", ['rules_accepted' => '1', 'display_name' => 'Dimas B'], $tokB));
$feed = step('5b. Pengguna B melihat feed komunitas', call($kernel, 'GET', "community/feed", [], $tokB));
$visible = collect($feed['items'] ?? [])->first(fn($i) => $i['id'] === $pid);
if ($visible) {
    echo "   Postingan A TERLIHAT oleh B! status: {$visible['moderation_status']}, reaction_count: {$visible['reaction_count']}, comment_count: {$visible['comment_count']}\n";
    echo "   author: {$visible['author']['display_name']}\n";
} else {
    echo "   WARNING: postingan A TIDAK TERLIHAT di feed B!\n";
}

// ---------- 6. Pengguna B memberi reaksi 'support' ----------
$postAfterReact = step('6. Pengguna B tekan reaksi support', call($kernel, 'POST', "community/posts/$pid/reactions", ['reaction_type' => 'support'], $tokB));
echo "   reaction_count: {$postAfterReact['reaction_count']}, my_reaction: {$postAfterReact['my_reaction']}\n";
if ($postAfterReact['reaction_count'] !== 1) { echo "   FAIL: reaction_count salah\n"; exit(1); }

// ---------- 7. Pengguna B menulis komentar ----------
$cResp = call($kernel, 'POST', "community/posts/$pid/comments", ['content' => 'Semangat ya! Dukungan dari B.', 'sharing_acknowledged' => '1'], $tokB);
$commentData = step('7. Pengguna B menulis komentar', $cResp);
$cmid = $commentData['id'];
echo '   Status moderasi komentar: '.$commentData['moderation_status']."\n";

// Approve comment jika pending
[$code, $cq] = call($kernel, 'GET', "community/moderation?kind=comment", [], $tokAdm);
$cItem = collect($cq['data']['items'] ?? [])->first(fn($i) => $i['id'] === $cmid);
if ($cItem && $commentData['moderation_status'] !== 'approved') {
    step('7b. Admin setujui komentar', call($kernel, 'POST', "community/moderation/comment/$cmid", ['action' => 'approve', 'revision' => $cItem['revision'], 'note' => 'Komentar baik'], $tokAdm));
}

// ---------- 8. Komentar dilihat oleh A dan B ----------
foreach ([['A', $tokA], ['B', $tokB]] as [$who, $tok]) {
    [$code, $cb] = call($kernel, 'GET', "community/posts/$pid/comments", [], $tok);
    if (!$cb['success']) { echo "8. komentar dilihat $who => FAIL [$code] {$cb['message']}\n"; exit(1); }
    $found = collect($cb['data']['items'] ?? [])->first(fn($i) => $i['id'] === $cmid);
    echo $found
        ? "8. komentar dilihat $who => OK (author {$found['author']['display_name']}: \"{$found['content']}\")\n"
        : "8. komentar dilihat $who => WARNING komentar tidak terlihat!\n";
}

// ---------- 9. Notifikasi untuk A ----------
[, $nb] = call($kernel, 'GET', 'notifications', [], $tokA);
$items = collect($nb['data'] ?? []);
echo '9. Notifikasi milik A: '.($items->count() ? implode(', ', $items->pluck('notification_type')->all()) : '(kosong)')."\n";

// ---------- 10. Reaksi B terlihat oleh A ----------
[, $postForA] = call($kernel, 'GET', "community/posts/$pid", [], $tokA);
echo "10. A melihat reaction_count: {$postForA['data']['reaction_count']}\n";

// ---------- Cleanup ----------
App\Models\Community::where('id', $cid)->forceDelete();
App\Models\User::where('email', 'like', "e2e%$suffix@test.invalid")->forceDelete();
echo "\nSelesai. (data e2e dibersihkan)\n";
