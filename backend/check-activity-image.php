<?php
require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use App\Models\SupportActivity;
use App\Models\User;
use Illuminate\Support\Facades\{Hash, Http, DB};

Http::fake(["*community/moderate" => Http::response(["status" => "safe", "confidence" => 0.96, "categories" => [], "mode" => "model"])]);

$images = [
    "Orientasi Ruang yang Nyaman" => "https://images.pexels.com/photos/6173718/pexels-photo-6173718.jpeg?cs=srgb&w=800",
    "Jeda Napas Alami" => "https://images.pexels.com/photos/6648567/pexels-photo-6648567.jpeg?cs=srgb&w=800",
    "Refleksi Satu Hal Kecil" => "https://images.pexels.com/photos/6541165/pexels-photo-6541165.jpeg?cs=srgb&w=800",
];
foreach ($images as $title => $url) {
    $n = SupportActivity::where("title", $title)->update(["image_url" => $url]);
    echo "update '$title' => $n baris\n";
}

$extra = [
    [
        "Peregangan Lembut", "relaxation", ["fatigue", "anxiety"],
        "Regangkan bahu dan leher pelan-pelan, boleh sambil duduk.",
        "https://images.pexels.com/photos/6958256/pexels-photo-6958256.jpeg?cs=srgb&w=800",
        ["Duduk tegak dengan bahu rileks.", "Putar bahu perlahan lima kali ke belakang.", "Condongkan kepala ke kanan lalu kiri, masing-masing lima detik."],
    ],
    [
        "Buku Harian Bunga Kecil", "reflection", ["hope", "gratitude"],
        "Tulis satu hal baik hari ini, sekecil apa pun itu.",
        "https://images.pexels.com/photos/9031745/pexels-photo-9031745.jpeg?cs=srgb&w=800",
        ["Siapkan buku atau catatan di ponsalmu.", "Tulis satu hal baik yang terjadi hari ini.", "Baca ulang saat hari terasa berat."],
    ],
];
foreach ($extra as [$title, $category, $tags, $desc, $img, $steps]) {
    if (!SupportActivity::where("title", $title)->exists()) {
        $a = new SupportActivity();
        $a->fill([
            "title" => $title, "description" => $desc, "category" => $category,
            "duration_minutes" => 3, "suitability_tags" => $tags, "image_url" => $img,
            "steps" => $steps,
            "contraindication_notes" => "Lewati jika tidak nyaman. Ini bukan terapi medis; ikuti arahan tim perawatan.",
            "medically_reviewed" => false, "active" => true,
        ])->save();
        echo "tambah '$title'\n";
    } else {
        echo "'$title' sudah ada\n";
    }
}

// ---- E2E: admin simpan aktivitas via API dengan image_url, pasien melihatnya ----
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
function call($kernel, string $method, string $uri, array $data = [], ?string $token = null): array {
    app('auth')->forgetGuards();
    $headers = ['HTTP_ACCEPT' => 'application/json'];
    if ($token) { $headers['HTTP_AUTHORIZATION'] = 'Bearer '.$token; }
    $req = Illuminate\Http\Request::create("/api/$uri", $method, $data, [], [], $headers);
    $res = $kernel->handle($req);
    $kernel->terminate($req, $res);
    return [$res->getStatusCode(), json_decode($res->getContent(), true)];
}

$admin = User::where("email", "admin@hopely.care")->first();
$tokAdm = $admin->createToken("admin")->plainTextToken;
[$code, $saved] = call($kernel, 'POST', 'admin/activities', [
    'title' => 'Uji Gambar Aktivitas',
    'description' => 'Aktivitas uji dengan gambar.',
    'category' => 'relaxation',
    'duration_minutes' => 4,
    'suitability_tags' => ['anxiety'],
    'steps' => ['Langkah satu', 'Langkah dua'],
    'contraindication_notes' => null,
    'medically_reviewed' => false,
    'active' => true,
    'image_url' => 'https://images.pexels.com/photos/6648567/pexels-photo-6648567.jpeg?cs=srgb&w=800',
], $tokAdm);
echo "admin POST aktivitas + gambar => HTTP $code image_url=".($saved['data']['image_url'] ?? '(kosong)')."\n";
$testId = $saved['data']['id'] ?? null;

$patient = User::where("email", "patient.demo@hopely.invalid")->first();
$tokP = $patient->createToken("mobile")->plainTextToken;
[$code, $list] = call($kernel, 'GET', 'activities', [], $tokP);
$rows = collect($list['data'] ?? []);
$withImg = $rows->filter(fn($r) => str_starts_with((string)($r['image_url'] ?? ''), 'https://'))->count();
echo "pasien GET /activities => HTTP $code total=".$rows->count()." dengan gambar=$withImg\n";
foreach ($rows->take(6) as $r) { echo "   - {$r['title']} | ".substr((string)$r['image_url'], 0, 60)."\n"; }

if ($testId) { SupportActivity::whereKey($testId)->first()?->delete(); echo "(uji dibersihkan)\n"; }
