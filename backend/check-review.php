<?php
require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
Illuminate\Support\Facades\Auth::guard('sanctum')->setUser(App\Models\User::where('email', 'admin@hopely.care')->first());

$p = App\Models\CommunityPost::whereIn('moderation_status', ['pending', 'flagged'])->first();
if (!$p) { echo "no pending\n"; exit; }
$pItem = ['id' => $p->id, 'revision' => $p->revision, 'community_name' => $p->community?->name];
if (!$pItem) { echo "no pending\n"; exit; }
echo "Pending post: {$pItem['id']} revision {$pItem['revision']}\n";

$req = new Illuminate\Http\Request([], ['action' => 'approve', 'revision' => $pItem['revision'], 'note' => 'Konten sesuai aturan']);
$req->setMethod('POST');
$adminUser = App\Models\User::where('email', 'admin@hopely.care')->first();
Illuminate\Support\Facades\Auth::guard('sanctum')->setUser($adminUser);
$req->setUserResolver(fn() => $adminUser);
Illuminate\Support\Facades\Gate::forUser($adminUser);

try {
    $admin = App\Models\User::where('email', 'admin@hopely.care')->first();
    $post = App\Models\CommunityPost::findOrFail($pItem['id']);
    $community = $post->community;
    echo "post community=" . ($community?->name ?? 'NULL') . " is_active=" . var_export($community?->is_active, true) . "\n";
    $pol = new App\Policies\CommunityPolicy();
    echo "policy->moderate(admin, community): " . var_export($pol->moderate($admin, $community), true) . "\n";
    echo "Gate::forUser(admin)->check(moderate, community): " . var_export(Illuminate\Support\Facades\Gate::forUser($admin)->check('moderate', $community), true) . "\n";
    $resp = app(App\Http\Controllers\CommunitySafetyController::class)->review($req, 'post', $pItem['id']);
    echo "review OK: " . json_encode($resp->getData(true), JSON_UNESCAPED_UNICODE) . "\n";
} catch (Illuminate\Validation\ValidationException $e) {
    echo "VALIDATION 422: " . json_encode($e->errors(), JSON_UNESCAPED_UNICODE) . "\n";
} catch (Illuminate\Auth\Access\AuthorizationException $e) {
    echo "AUTHZ 403: {$e->getMessage()} at {$e->getFile()}:{$e->getLine()}\n";
} catch (\Throwable $e) {
    echo get_class($e) . ": {$e->getMessage()} at {$e->getFile()}:{$e->getLine()}\n";
}
