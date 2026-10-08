<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up(): void
    {
        Schema::create("users", function (Blueprint $t) {
            $t->uuid("id")->primary();
            $t->string("name", 100);
            $t->string("email")->unique();
            $t->string("password");
            $t->enum("role", ["PATIENT", "CAREGIVER", "ADMIN"]);
            $t->timestamp("email_verified_at")->nullable();
            $t->unsignedBigInteger("consent_revision")->default(0);
            $t->rememberToken();
            $t->timestamps();
        });
        Schema::create("personal_access_tokens", function (Blueprint $t) {
            $t->id();
            $t->uuidMorphs("tokenable");
            $t->text("name");
            $t->string("token", 64)->unique();
            $t->text("abilities")->nullable();
            $t->timestamp("last_used_at")->nullable();
            $t->timestamp("expires_at")->nullable()->index();
            $t->timestamps();
        });
        Schema::create("patient_profiles", function (Blueprint $t) {
            $this->owned($t);
            $t->unique("user_id");
            $t->string("display_name", 100);
            $t->unsignedSmallInteger("birth_year")->nullable();
            $t->text("cancer_context")->nullable();
            $t->string("treatment_phase", 100)->nullable();
            $t->string("timezone")->default("Asia/Jakarta");
            $t->boolean("onboarding_completed")->default(false);
        });
        Schema::create("consents", function (Blueprint $t) {
            $this->owned($t);
            $t->string("consent_type", 64);
            $t->string("consent_version", 20)->default("1.0");
            $t->boolean("accepted")->default(false);
            $t->timestamp("accepted_at")->nullable();
            $t->timestamp("revoked_at")->nullable();
            $t->unique(["user_id", "consent_type"]);
        });
        Schema::create("daily_checkins", function (Blueprint $t) {
            $this->owned($t);
            $t->date("checkin_date");
            foreach (["mood", "anxiety", "energy", "sleep", "pain"] as $k) {
                $t->unsignedTinyInteger($k . "_score");
            }
            $t->text("optional_note")->nullable();
            $t->boolean("ai_analysis_allowed")->default(false);
            $t->json("emotion_signal")->nullable();
            $t->unique(["user_id", "checkin_date"]);
        });
        Schema::create("symptom_logs", function (Blueprint $t) {
            $this->owned($t);
            $t->timestamp("logged_at")->useCurrent();
            foreach (
                ["pain", "fatigue", "nausea", "dizziness", "appetite", "sleep_quality"]
                as $k
            ) {
                $t->unsignedTinyInteger($k);
            }
            $t->text("optional_note")->nullable();
            $t->index(["user_id", "logged_at"]);
        });
        Schema::create("treatments", function (Blueprint $t) {
            $this->owned($t);
            $t->string("title", 150);
            $t->string("treatment_type", 80);
            $t->timestamp("scheduled_at")->useCurrent();
            $t->text("location")->nullable();
            $t->text("notes")->nullable();
            $t->enum("status", ["scheduled", "completed", "cancelled"])->default("scheduled");
            $t->index(["user_id", "scheduled_at"]);
        });
        Schema::create("journals", function (Blueprint $t) {
            $this->owned($t);
            $t->text("title")->nullable();
            $t->text("content");
            $t->date("journal_date");
            $t->boolean("ai_analysis_allowed")->default(false);
            $t->index(["user_id", "journal_date"]);
        });
        Schema::create("journal_ai_insights", function (Blueprint $t) {
            $this->owned($t);
            $t->foreignUuid("journal_id")->unique()->constrained("journals")->cascadeOnDelete();
            $t->string("primary_emotion", 40);
            $t->json("emotion_scores");
            $t->json("themes");
            $t->timestamp("generated_at")->useCurrent();
            $t->string("model_version", 100);
        });
        Schema::create("chat_sessions", function (Blueprint $t) {
            $this->owned($t);
            $t->string("title", 100)->default("Percakapan pribadi");
        });
        Schema::create("chat_messages", function (Blueprint $t) {
            $this->owned($t);
            $t->foreignUuid("chat_session_id")->constrained()->cascadeOnDelete();
            $t->enum("sender", ["user", "assistant"]);
            $t->text("content");
            $t->string("safety_level", 20)->default("NONE");
            $t->index(["chat_session_id", "created_at"]);
        });
        Schema::create("ai_insight_snapshots", function (Blueprint $t) {
            $this->owned($t);
            $t->date("snapshot_date");
            $t->json("report_json");
            $t->string("model_version", 100);
            $t->index(["user_id", "snapshot_date"]);
        });
        Schema::create("support_activities", function (Blueprint $t) {
            $t->uuid("id")->primary();
            $t->string("title", 150);
            $t->text("description");
            $t->string("category", 50);
            $t->unsignedSmallInteger("duration_minutes");
            $t->json("suitability_tags");
            $t->json("steps");
            $t->text("contraindication_notes")->nullable();
            $t->boolean("medically_reviewed")->default(false);
            $t->boolean("active")->default(true);
            $t->timestamps();
        });
        Schema::create("activity_recommendations", function (Blueprint $t) {
            $this->owned($t);
            $t->foreignUuid("support_activity_id")->constrained()->cascadeOnDelete();
            $t->text("reason");
            $t->json("metadata")->nullable();
            $t->timestamp("generated_at")->useCurrent();
            $t->timestamp("completed_at")->nullable();
        });
        Schema::create("doctor_visit_reports", function (Blueprint $t) {
            $this->owned($t);
            $t->date("period_start");
            $t->date("period_end");
            $t->longText("report_json");
            $t->timestamp("generated_at")->useCurrent();
        });
        Schema::create("caregiver_links", function (Blueprint $t) {
            $t->uuid("id")->primary();
            $t->foreignUuid("patient_user_id")->constrained("users")->cascadeOnDelete();
            $t->foreignUuid("caregiver_user_id")
                ->nullable()
                ->constrained("users")
                ->cascadeOnDelete();
            $t->string("invited_email");
            $t->string("relationship_label", 80);
            $t->enum("invitation_status", ["pending", "accepted", "revoked"])->default("pending");
            $t->string("invitation_hash", 64)->nullable()->unique();
            $t->timestamp("expires_at")->nullable();
            $t->timestamps();
            $t->unique(["patient_user_id", "invited_email"]);
        });
        Schema::create("caregiver_permissions", function (Blueprint $t) {
            $t->uuid("id")->primary();
            $t->foreignUuid("caregiver_link_id")->unique()->constrained()->cascadeOnDelete();
            foreach (
                [
                    "view_wellbeing_summary",
                    "view_treatment_schedule",
                    "receive_support_alert",
                    "view_symptom_summary",
                    "view_activity_status",
                ]
                as $k
            ) {
                $t->boolean("can_" . $k)->default(false);
            }
            $t->timestamps();
        });
        Schema::create("device_tokens", function (Blueprint $t) {
            $this->owned($t);
            $t->text("token");
            $t->string("token_hash", 64)->unique();
            $t->string("platform", 20);
        });
        Schema::create("notifications", function (Blueprint $t) {
            $this->owned($t);
            $t->string("notification_type", 60);
            $t->string("title", 150);
            $t->string("body", 500);
            $t->timestamp("read_at")->nullable();
            $t->string("dedupe_key", 180)->unique();
        });
        Schema::create("audit_logs", function (Blueprint $t) {
            $t->uuid("id")->primary();
            $t->foreignUuid("actor_user_id")->constrained("users")->cascadeOnDelete();
            $t->string("event", 100);
            $t->string("resource_type", 80);
            $t->uuid("resource_id")->nullable();
            $t->json("metadata")->nullable();
            $t->timestamps();
        });
    }
    private function owned(Blueprint $t): void
    {
        $t->uuid("id")->primary();
        $t->foreignUuid("user_id")->constrained("users")->cascadeOnDelete();
        $t->timestamps();
    }
    public function down(): void
    {
        foreach (
            [
                "audit_logs",
                "notifications",
                "device_tokens",
                "caregiver_permissions",
                "caregiver_links",
                "doctor_visit_reports",
                "activity_recommendations",
                "support_activities",
                "ai_insight_snapshots",
                "chat_messages",
                "chat_sessions",
                "journal_ai_insights",
                "journals",
                "treatments",
                "symptom_logs",
                "daily_checkins",
                "consents",
                "patient_profiles",
                "personal_access_tokens",
                "users",
            ]
            as $name
        ) {
            Schema::dropIfExists($name);
        }
    }
};
