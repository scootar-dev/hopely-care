<?php
require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
$request = Illuminate\Http\Request::create('/api/admin/auth/login', 'POST', ['email' => 'admin@hopely.care', 'password' => 'HopelyAdmin123!'], [], [], ['HTTP_ACCEPT' => 'application/json']);
$response = $kernel->handle($request);
echo 'Admin login HTTP '.$response->getStatusCode().PHP_EOL;
$data = json_decode($response->getContent(), true);
if ($response->getStatusCode() === 200) {
    echo 'Role: '.$data['data']['user']['role'].PHP_EOL;
    Laravel\Sanctum\PersonalAccessToken::findToken($data['data']['token'])?->delete();
}
$kernel->terminate($request, $response);
