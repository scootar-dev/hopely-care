<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // UUID primary keys follow the existing Hopely schema; no duplicate numeric ID.
        Schema::create("communities", function (Blueprint $t) {
            $t->uuid("id")->primary();
            $t->string("name", 100);
            $t->string("slug", 120)->unique();
            $t->text("description");
            $t->string("category", 40)->index();
            $t->string("cancer_type", 100)->nullable();
            $t->string("treatment_phase", 100)->nullable();
            $t->string("support_type", 100)->nullable();
            $t->string("image_url")->nullable();
            $t->boolean("is_active")->default(true)->index();
            $t->timestamps();
        });
        Schema::create("community_preferences", function (Blueprint $t) {
            $t->uuid("id")->primary();
            $t->foreignUuid("user_id")->unique()->constrained()->cascadeOnDelete();
            $t->string("display_name", 60)->default("Anggota");
            $t->boolean("notifications_enabled")->default(true);
            $t->boolean("recommendation_enabled")->default(false);
            $t->text("interests")->nullable();
            $t->timestamps();
        });
        Schema::create("community_members", function (Blueprint $t) {
            $t->uuid("id")->primary();
            $t->foreignUuid("community_id")->constrained()->cascadeOnDelete();
            $t->foreignUuid("user_id")->constrained()->cascadeOnDelete();
            $t->enum("role", ["member", "moderator", "admin"])->default("member");
            $t->enum("status", ["active", "pending", "banned", "left"])->default("active");
            $t->timestamp("joined_at")->nullable();
            $t->timestamps();
            $t->unique(["community_id", "user_id"]);
            $t->index(["user_id", "status"]);
        });
        Schema::create("community_posts", function (Blueprint $t) {
            $t->uuid("id")->primary();
            $t->foreignUuid("community_id")->constrained()->cascadeOnDelete();
            $this->content($t);
            $t->string("image_path")->nullable();
            $t->boolean("is_demo")->default(false);
            $t->index(["community_id", "moderation_status", "created_at"], "community_feed_index");
        });
        Schema::create("community_comments", function (Blueprint $t) {
            $t->uuid("id")->primary();
            $t->foreignUuid("post_id")->constrained("community_posts")->cascadeOnDelete();
            $this->content($t);
            $t->index(["post_id", "moderation_status", "created_at"], "community_comment_index");
        });
        Schema::create("community_reactions", function (Blueprint $t) {
            $t->uuid("id")->primary();
            $t->foreignUuid("post_id")->constrained("community_posts")->cascadeOnDelete();
            $t->foreignUuid("user_id")->constrained()->cascadeOnDelete();
            $t->enum("reaction_type", ["support", "encouragement", "thanks"]);
            $t->timestamp("created_at")->useCurrent();
            $t->unique(["post_id", "user_id"]);
        });
        Schema::create("community_reports", function (Blueprint $t) {
            $t->uuid("id")->primary();
            $t->foreignUuid("reporter_user_id")->constrained("users")->cascadeOnDelete();
            // Explicit type allowlist in FormRequest; never accept arbitrary model names.
            $t->enum("reportable_type", ["post", "comment"]);
            $t->uuid("reportable_id");
            $t->foreignUuid("community_id")->constrained()->cascadeOnDelete();
            $t->string("reason", 40);
            $t->text("description")->nullable();
            $t->enum("status", ["pending", "reviewed", "resolved", "dismissed"])->default(
                "pending"
            );
            $t->foreignUuid("reviewed_by")->nullable()->constrained("users")->nullOnDelete();
            $t->timestamp("reviewed_at")->nullable();
            $t->timestamps();
            $t->index(["reportable_type", "reportable_id"]);
            $t->index(["community_id", "status"]);
            $t->unique(
                ["reporter_user_id", "reportable_type", "reportable_id"],
                "community_report_once"
            );
        });
        Schema::create("blocked_users", function (Blueprint $t) {
            $t->uuid("id")->primary();
            $t->foreignUuid("user_id")->constrained()->cascadeOnDelete();
            $t->foreignUuid("blocked_user_id")->constrained("users")->cascadeOnDelete();
            $t->timestamp("created_at")->useCurrent();
            $t->unique(["user_id", "blocked_user_id"]);
        });
    }

    private function content(Blueprint $t): void
    {
        $t->foreignUuid("user_id")->constrained()->cascadeOnDelete();
        $t->longText("content");
        $t->enum("moderation_status", ["pending", "approved", "flagged", "removed"])->default(
            "pending"
        );
        $t->text("moderation_meta")->nullable();
        $t->unsignedInteger("revision")->default(1);
        $t->foreignUuid("reviewed_by")->nullable()->constrained("users")->nullOnDelete();
        $t->timestamp("reviewed_at")->nullable();
        $t->timestamps();
        $t->softDeletes();
    }

    public function down(): void
    {
        foreach (
            [
                "blocked_users",
                "community_reports",
                "community_reactions",
                "community_comments",
                "community_posts",
                "community_members",
                "community_preferences",
                "communities"
            ]
            as $table
        ) {
            Schema::dropIfExists($table);
        }
    }
};
