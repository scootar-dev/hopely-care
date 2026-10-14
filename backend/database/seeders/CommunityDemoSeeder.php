<?php
namespace Database\Seeders;

use App\Models\{Community, CommunityMember, CommunityPost, CommunityPreference, User};
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class CommunityDemoSeeder extends Seeder
{
    public function run(): void
    {
        if (app()->environment("production")) {
            throw new \RuntimeException("Synthetic community data is disabled in production.");
        }
        $this->call(CommunitySeeder::class);
        foreach (
            [
                [
                    "pejuang-kanker-payudara",
                    "Hari ini aku senang bisa berbincang dengan keluarga. Hal kecil, tetapi berarti untukku."
                ],
                [
                    "menjalani-kemoterapi",
                    "Besok aku menjalani kemoterapi ketiga. Masih deg-degan, tapi membaca cerita kalian cukup membantu."
                ],
                [
                    "baru-didiagnosis",
                    "Aku baru bergabung dan masih belajar menerima kabar ini. Untuk hari ini, aku ingin didengarkan dulu."
                ],
                [
                    "survivor-pemulihan",
                    "Aku sedang menata rutinitas pelan-pelan. Senang punya ruang untuk berbagi langkah kecil."
                ],
                [
                    "dukungan-emosional",
                    "Terima kasih sudah hadir di sini. Semoga kita bisa memberi ruang untuk perasaan masing-masing."
                ]
            ]
            as $i => [$slug, $content]
        ) {
            $email = "community-synthetic-" . $i . "@hopely.invalid";
            if (User::where("email", $email)->exists()) {
                continue;
            }
            $user = new User();
            $user
                ->forceFill([
                    "name" => "Cerita Contoh " . ($i + 1),
                    "email" => $email,
                    "password" => Str::random(64),
                    "role" => "PATIENT"
                ])
                ->save();
            $preference = new CommunityPreference();
            $preference
                ->forceFill([
                    "user_id" => $user->id,
                    "display_name" => "Sahabat " . ($i + 1) . " (Demo Sintetik)"
                ])
                ->save();
            $community = Community::where("slug", $slug)->firstOrFail();
            $member = new CommunityMember();
            $member
                ->forceFill([
                    "community_id" => $community->id,
                    "user_id" => $user->id,
                    "role" => "member",
                    "status" => "active",
                    "joined_at" => now()
                ])
                ->save();
            $post = new CommunityPost();
            $post
                ->forceFill([
                    "community_id" => $community->id,
                    "user_id" => $user->id,
                    "content" => $content,
                    "moderation_status" => "approved",
                    "is_demo" => true,
                    "moderation_meta" => ["mode" => "synthetic_seed"]
                ])
                ->save();
        }
    }
}
