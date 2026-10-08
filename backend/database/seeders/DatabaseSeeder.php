<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\{
    User,
    PatientProfile,
    DailyCheckin,
    SymptomLog,
    Treatment,
    Journal,
    SupportActivity,
    CaregiverLink,
    CaregiverPermission
};
use App\Services\ConsentService;
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        if (app()->environment("production")) {
            throw new \RuntimeException("Synthetic seeding is disabled in production.");
        }
        $password = env("DEMO_PASSWORD");
        if (!$password || strlen($password) < 12) {
            throw new \RuntimeException("Set DEMO_PASSWORD (at least 12 characters) in .env.");
        }
        if (User::where("email", "patient.demo@hopely.invalid")->exists()) {
            $this->command?->info("Demo already exists; preserving existing records.");
            return;
        }
        DB::transaction(function () use ($password) {
            $patient = new User();
            $patient
                ->forceFill([
                    "name" => "Sarah (Demo Sintetik)",
                    "email" => "patient.demo@hopely.invalid",
                    "password" => $password,
                    "role" => "PATIENT",
                ])
                ->save();
            $caregiver = new User();
            $caregiver
                ->forceFill([
                    "name" => "Dimas (Demo Sintetik)",
                    "email" => "caregiver.demo@hopely.invalid",
                    "password" => $password,
                    "role" => "CAREGIVER",
                ])
                ->save();
            $p = new PatientProfile();
            $p->forceFill([
                "user_id" => $patient->id,
                "display_name" => "Sarah (Demo)",
                "timezone" => "Asia/Jakarta",
                "onboarding_completed" => true,
            ])->save();
            foreach (ConsentService::TYPES as $type) {
                app(ConsentService::class)->set($patient->id, $type, true);
            }
            for ($i = 0; $i < 14; $i++) {
                $date = now("Asia/Jakarta")
                    ->startOfDay()
                    ->subDays(13 - $i);
                $mood = $i < 4 ? 4 : ($i < 8 ? 3 : ($i < 10 ? 4 : 2));
                $anxiety = $i < 9 ? 2 : ($i < 11 ? 3 : 4);
                $sleep = $i < 5 ? 4 : ($i < 8 ? 2 : ($i < 10 ? 3 : 2));
                $energy = $i >= 5 && $i <= 7 ? 2 : 3;
                $c = new DailyCheckin();
                $c->forceFill([
                    "user_id" => $patient->id,
                    "checkin_date" => $date->toDateString(),
                    "mood_score" => $mood,
                    "anxiety_score" => $anxiety,
                    "sleep_score" => $sleep,
                    "energy_score" => $energy,
                    "pain_score" => 3,
                    "optional_note" => null,
                    "ai_analysis_allowed" => false,
                ])->save();
                $s = new SymptomLog();
                $s->forceFill([
                    "user_id" => $patient->id,
                    "logged_at" => $date->copy()->addHours(8)->utc(),
                    "pain" => 3,
                    "fatigue" => $i >= 5 && $i <= 7 ? 5 : 2,
                    "nausea" => $i >= 5 && $i <= 7 ? 3 : 1,
                    "dizziness" => 1,
                    "appetite" => 3,
                    "sleep_quality" => $sleep,
                ])->save();
            }
            foreach ([[-9, "completed"], [1, "scheduled"]] as [$offset, $status]) {
                $t = new Treatment();
                $t->forceFill([
                    "user_id" => $patient->id,
                    "title" => "Jadwal Kemoterapi (Demo)",
                    "treatment_type" => "chemotherapy",
                    "scheduled_at" => now("Asia/Jakarta")
                        ->startOfDay()
                        ->addDays($offset)
                        ->addHours(9)
                        ->utc(),
                    "status" => $status,
                ])->save();
            }
            $j = new Journal();
            $j->forceFill([
                "user_id" => $patient->id,
                "title" => "Catatan pribadi (demo)",
                "content" =>
                    "Saya takut dengan kemoterapi berikutnya dan akhir-akhir ini sulit tidur.",
                "journal_date" => now("Asia/Jakarta")->toDateString(),
                "ai_analysis_allowed" => false,
            ])->save();
            $link = new CaregiverLink();
            $link
                ->forceFill([
                    "patient_user_id" => $patient->id,
                    "caregiver_user_id" => $caregiver->id,
                    "invited_email" => $caregiver->email,
                    "relationship_label" => "Keluarga (demo)",
                    "invitation_status" => "accepted",
                ])
                ->save();
            $permission = new CaregiverPermission();
            $permission
                ->forceFill([
                    "caregiver_link_id" => $link->id,
                    "can_view_wellbeing_summary" => true,
                    "can_view_symptom_summary" => true,
                    "can_view_treatment_schedule" => false,
                    "can_receive_support_alert" => true,
                    "can_view_activity_status" => false,
                ])
                ->save();
            foreach (
                [
                    [
                        "Orientasi Ruang yang Nyaman",
                        "grounding",
                        ["anxiety", "fear"],
                        [
                            "Cari posisi yang terasa nyaman.",
                            "Perhatikan beberapa benda yang ada di sekitarmu.",
                            "Sebutkan satu hal kecil yang ingin kamu lakukan untuk dirimu hari ini.",
                        ],
                    ],
                    [
                        "Jeda Napas Alami",
                        "relaxation",
                        ["anxiety", "fatigue"],
                        [
                            "Pilih posisi yang nyaman dan tidak memaksakan tubuh.",
                            "Perhatikan napas sebagaimana adanya, tanpa menahan atau memaksakan kedalamannya.",
                            "Berhenti jika tidak nyaman dan kembali pada aktivitas yang terasa ringan.",
                        ],
                    ],
                    [
                        "Refleksi Satu Hal Kecil",
                        "reflection",
                        ["hope", "loneliness"],
                        [
                            "Pikirkan satu momen kecil hari ini.",
                            "Apa yang ingin kamu akui dari usaha dirimu?",
                            "Kamu boleh menyimpannya untuk diri sendiri.",
                        ],
                    ],
                ]
                as [$title, $category, $tags, $steps]
            ) {
                $a = new SupportActivity();
                $a->fill([
                    "title" => $title,
                    "description" =>
                        "Aktivitas dukungan umum yang dapat kamu pilih sesuai kenyamanan.",
                    "category" => $category,
                    "duration_minutes" => 3,
                    "suitability_tags" => $tags,
                    "steps" => $steps,
                    "contraindication_notes" =>
                        "Lewati jika tidak nyaman. Ini bukan terapi medis; ikuti arahan tim perawatan.",
                    "medically_reviewed" => false,
                    "active" => true,
                ])->save();
            }
        });
    }
}
