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
    return [$res->getStatusCode(), json_decode($res->getContent(), true), $res];
}
[, $adm] = call($kernel, 'POST', 'admin/auth/login', ['email' => 'admin@hopely.care', 'password' => 'HopelyAdmin123!']);
$tokAdm = $adm['data']['token'];
[, $q] = call($kernel, 'GET', 'community/moderation', [], $tokAdm);
$pItem = collect($q['data']['items'] ?? [])->first(fn($i) => $i['moderation_status'] === 'pending');
if (!$pItem) { echo "no pending item\n"; exit; }
$pidToApprove = $pItem['id'];
echo "Menyetujui post $pidToApprove (community: {$pItem['community_name']})\n";
[$code, $res, $http] = call($kernel, 'POST', "community/moderation/post/$pidToApprove", ['action' => 'approve', 'revision' => $pItem['revision'], 'note' => 'Konten sesuai aturan'], $tokAdm);
echo "approve => HTTP $code: ".json_encode($res, JSON_UNESCAPED_UNICODE)."\n";
// manual policy eval
use Illuminate\Support\Facades\Gate;
$post = App\Models\CommunityPost::find($pidToApprove);
$admUser = App\Models\User::find($adm['data']['user']['id']);
echo "role admin: {$admUser->role}\n";
echo "general:missing_policy? ";
var_dump(Gate::has([$post->community], 'moderate') ? true : false);
echo "member check: ".var_export(App\Models\CommunityMember::where('community_id', $post->community_id)->where('user_id', $admUser->id)->exists(), true)."\n";
