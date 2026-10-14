<?php
namespace Database\Seeders;

use App\Models\Community;
use Illuminate\Database\Seeder;

class CommunitySeeder extends Seeder
{
    public function run(): void
    {
        // Catalogue only: no demo accounts, fake members, or patient records.
        foreach (
            [
                [
                    "pejuang-kanker-payudara",
                    "Pejuang Kanker Payudara",
                    "cancer",
                    "kanker payudara",
                    null,
                    null,
                    "Berbagi pengalaman sehari-hari dan saling mendengarkan dalam perjalanan kanker payudara."
                ],
                [
                    "menjalani-kemoterapi",
                    "Menjalani Kemoterapi",
                    "treatment",
                    null,
                    "kemoterapi",
                    null,
                    "Tempat bercerita tentang perasaan dan dukungan selama menjalani kemoterapi."
                ],
                [
                    "baru-didiagnosis",
                    "Baru Didiagnosis",
                    "treatment",
                    null,
                    "baru didiagnosis",
                    null,
                    "Kamu boleh mulai perlahan. Temukan teman untuk mendengarkan di awal perjalananmu."
                ],
                [
                    "survivor-pemulihan",
                    "Survivor & Pemulihan",
                    "survivor",
                    null,
                    "pemulihan",
                    null,
                    "Merayakan langkah kecil dan saling menemani saat menata keseharian kembali."
                ],
                [
                    "dukungan-emosional",
                    "Ruang Dukungan Emosional",
                    "emotional",
                    null,
                    null,
                    "dukungan emosional",
                    "Ruang untuk mengungkapkan perasaan, mendengarkan, dan menguatkan satu sama lain."
                ]
            ]
            as [$slug, $name, $category, $cancer, $phase, $support, $description]
        ) {
            Community::firstOrCreate(
                ["slug" => $slug],
                [
                    "name" => $name,
                    "category" => $category,
                    "cancer_type" => $cancer,
                    "treatment_phase" => $phase,
                    "support_type" => $support,
                    "description" => $description,
                    "is_active" => true
                ]
            );
        }
    }
}
