<?php
namespace Tests\Feature;

use App\Models\{
    BlockedUser,
    Community,
    CommunityComment,
    CommunityMember,
    CommunityPost,
    CommunityPreference,
    CommunityReport,
    User
};
use Database\Seeders\CommunitySeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\{DB, Http, Storage};
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CommunityTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config([
            "services.ai.key" => "synthetic-internal-key",
            "services.ai.url" => "http://ai.test"
        ]);
        Http::fake([
            "*community/moderate" => Http::response([
                "status" => "safe",
                "confidence" => 0.96,
                "categories" => [],
                "reason" => "Synthetic safe result",
                "mode" => "model"
            ])
        ]);
        Storage::fake("local");
    }

    private function user(string $role = "PATIENT"): User
    {
        $u = new User();
        $u->forceFill([
            "name" => "Private account name",
            "email" => bin2hex(random_bytes(8)) . "@test.invalid",
            "password" => "synthetic-community-password",
            "role" => $role
        ])->save();
        $p = new CommunityPreference();
        $p->forceFill(["user_id" => $u->id, "display_name" => "Sahabat Uji"])->save();
        return $u;
    }

    private function community(): Community
    {
        return Community::create([
            "name" => "Ruang Uji",
            "slug" => bin2hex(random_bytes(8)),
            "description" => "Komunitas sintetis untuk pengujian.",
            "category" => "emotional"
        ]);
    }

    private function member(
        User $u,
        Community $c,
        string $role = "member",
        string $status = "active"
    ): CommunityMember {
        $m = new CommunityMember();
        $m->forceFill([
            "community_id" => $c->id,
            "user_id" => $u->id,
            "role" => $role,
            "status" => $status,
            "joined_at" => now()
        ])->save();
        return $m;
    }

    private function story(User $u, Community $c, string $status = "approved"): CommunityPost
    {
        $p = new CommunityPost();
        $p->forceFill([
            "community_id" => $c->id,
            "user_id" => $u->id,
            "content" => "Terima kasih sudah menemani.",
            "moderation_status" => $status
        ])->save();
        return $p;
    }

    private function text(string $content = "Hari ini aku merasa ditemani."): array
    {
        return ["content" => $content, "sharing_acknowledged" => true];
    }

    public function test_auth_membership_and_explicit_sharing_are_required(): void
    {
        $c = $this->community();
        $this->getJson("/api/communities")->assertUnauthorized();
        $this->postJson("/api/communities/$c->id/posts", $this->text())->assertUnauthorized();
        $u = $this->user();
        Sanctum::actingAs($u);
        $this->postJson("/api/communities/$c->id/posts", $this->text())->assertForbidden();
        $this->postJson("/api/communities/$c->id/join", [
            "display_name" => "Sahabat"
        ])->assertUnprocessable();
        $this->postJson("/api/communities/$c->id/join", [
            "display_name" => "Sahabat",
            "rules_accepted" => true,
            "role" => "admin"
        ])
            ->assertOk()
            ->assertJsonPath("data.community.membership_role", "member")
            ->assertJsonPath("data.community.member_count", 1);
        $this->postJson("/api/communities/$c->id/join", [
            "display_name" => "Sahabat",
            "rules_accepted" => true
        ])->assertOk();
        $this->assertDatabaseCount("community_members", 1);
        $this->postJson("/api/communities/$c->id/posts", [
            "content" => "Cerita uji."
        ])->assertUnprocessable();
        $this->postJson(
            "/api/communities/$c->id/posts",
            $this->text() + ["user_id" => $this->user()->id, "moderation_status" => "removed"]
        )
            ->assertCreated()
            ->assertJsonPath("data.author.id", $u->id)
            ->assertJsonPath("data.moderation_status", "approved");
        $this->assertStringNotContainsString(
            "Hari ini",
            DB::table("community_posts")->value("content")
        );
        $this->deleteJson("/api/communities/$c->id/leave")->assertOk();
        $this->postJson("/api/communities/$c->id/posts", $this->text())->assertForbidden();
    }

    public function test_ownership_and_revisions_prevent_edits_to_other_posts_or_stale_reviews(): void
    {
        $c = $this->community();
        $owner = $this->user();
        $other = $this->user();
        $this->member($owner, $c);
        $this->member($other, $c, "moderator");
        $p = $this->story($owner, $c);
        Sanctum::actingAs($other);
        $this->putJson(
            "/api/community/posts/$p->id",
            $this->text() + ["revision" => 1]
        )->assertForbidden();
        $this->deleteJson("/api/community/posts/$p->id")->assertForbidden();
        Sanctum::actingAs($owner);
        $this->putJson(
            "/api/community/posts/$p->id",
            $this->text("Cerita telah diperbarui.") + ["revision" => 1]
        )
            ->assertOk()
            ->assertJsonPath("data.revision", 2);
        Sanctum::actingAs($other);
        $this->postJson("/api/community/moderation/post/$p->id", [
            "action" => "remove",
            "revision" => 1,
            "note" => "Uji revisi lama"
        ])->assertConflict();
        Sanctum::actingAs($owner);
        $this->deleteJson("/api/community/posts/$p->id")->assertOk();
        $this->getJson("/api/community/posts/$p->id")->assertNotFound();
    }

    public function test_offline_mock_and_low_confidence_moderation_never_auto_publish(): void
    {
        $c = $this->community();
        $u = $this->user();
        $this->member($u, $c);
        Sanctum::actingAs($u);
        foreach (
            [
                [
                    "status" => "safe",
                    "mode" => "manual_review",
                    "confidence" => 1,
                    "categories" => []
                ],
                ["status" => "safe", "mode" => "model", "confidence" => 0.4, "categories" => []],
                [
                    "status" => "safe",
                    "mode" => "model",
                    "confidence" => 0.9,
                    "categories" => ["spam"]
                ]
            ]
            as $result
        ) {
            Http::fake(["*" => Http::response($result)]);
            $this->postJson("/api/communities/$c->id/posts", $this->text())
                ->assertCreated()
                ->assertJsonPath("data.moderation_status", "pending");
        }
        Http::fake(["*" => Http::response([], 503)]);
        $p = $this->postJson("/api/communities/$c->id/posts", $this->text())
            ->assertCreated()
            ->json("data.id");
        $this->getJson("/api/community/posts/$p")
            ->assertOk()
            ->assertJsonPath("data.moderation_status", "pending");
        Sanctum::actingAs($this->user());
        $this->getJson("/api/community/posts/$p")->assertForbidden();
        $this->getJson("/api/communities/$c->id/posts")
            ->assertOk()
            ->assertJsonCount(0, "data.items");
    }

    public function test_reports_and_moderator_scope_have_working_human_review(): void
    {
        $c = $this->community();
        $other = $this->community();
        $owner = $this->user();
        $mod = $this->user();
        $reader = $this->user();
        $this->member($mod, $c, "moderator");
        $p = $this->story($owner, $c);
        $outside = $this->story($owner, $other, "pending");
        Sanctum::actingAs($reader);
        $payload = [
            "reportable_type" => "post",
            "reportable_id" => $p->id,
            "reason" => "misinformation"
        ];
        $id = $this->postJson("/api/community/reports", $payload)->assertCreated()->json("data.id");
        $this->postJson("/api/community/reports", $payload)->assertCreated();
        $this->assertDatabaseCount("community_reports", 1);
        $this->getJson("/api/community/moderation")->assertForbidden();
        $this->postJson("/api/community/moderation/post/$p->id", [
            "action" => "remove",
            "revision" => 1,
            "note" => "Uji akses"
        ])->assertForbidden();
        Sanctum::actingAs($mod);
        $this->getJson("/api/community/moderation?kind=report")
            ->assertOk()
            ->assertJsonCount(1, "data.items");
        $this->postJson("/api/community/moderation/post/$outside->id", [
            "action" => "approve",
            "revision" => 1,
            "note" => "Di luar ruang"
        ])->assertForbidden();
        $this->postJson("/api/community/moderation/report/$id", [
            "action" => "remove",
            "revision" => 1,
            "note" => "Memuat klaim medis"
        ])->assertOk();
        $this->assertDatabaseHas("community_posts", [
            "id" => $p->id,
            "moderation_status" => "removed"
        ]);
        Sanctum::actingAs($reader);
        $this->getJson("/api/community/safety")
            ->assertOk()
            ->assertJsonPath("data.reports.items.0.status", "resolved");
        $this->assertDatabaseHas("notifications", [
            "user_id" => $reader->id,
            "notification_type" => "community_report_update"
        ]);
        $this->getJson("/api/community/posts/$p->id")->assertForbidden();
    }

    public function test_pending_post_can_be_approved_but_not_by_its_author(): void
    {
        $c = $this->community();
        $owner = $this->user();
        $mod = $this->user();
        $this->member($owner, $c, "moderator");
        $this->member($mod, $c, "moderator");
        $p = $this->story($owner, $c, "pending");
        Sanctum::actingAs($owner);
        $data = ["action" => "approve", "revision" => 1, "note" => "Cerita sesuai pedoman"];
        $this->postJson("/api/community/moderation/post/$p->id", $data)->assertForbidden();
        Sanctum::actingAs($mod);
        $this->postJson("/api/community/moderation/post/$p->id", $data)->assertOk();
        $this->assertDatabaseHas("community_posts", [
            "id" => $p->id,
            "moderation_status" => "approved",
            "reviewed_by" => $mod->id
        ]);
    }

    public function test_blocks_hide_posts_comments_and_reactions_in_both_directions(): void
    {
        $c = $this->community();
        $a = $this->user();
        $b = $this->user();
        $host = $this->user();
        $this->member($a, $c);
        $this->member($b, $c);
        $p = $this->story($b, $c);
        $public = $this->story($host, $c);
        Sanctum::actingAs($b);
        $comment = $this->postJson(
            "/api/community/posts/$public->id/comments",
            $this->text("Semangat untukmu.")
        )
            ->assertCreated()
            ->json("data.id");
        $this->postJson("/api/community/posts/$public->id/reactions", [
            "reaction_type" => "support"
        ])->assertOk();
        Sanctum::actingAs($a);
        $this->postJson("/api/users/$a->id/block")->assertUnprocessable();
        $this->postJson("/api/users/$b->id/block")->assertOk();
        $this->getJson("/api/community/posts/$p->id")->assertForbidden();
        $this->getJson("/api/community/posts/$public->id")
            ->assertOk()
            ->assertJsonPath("data.reaction_count", 0)
            ->assertJsonPath("data.comment_count", 0);
        $this->getJson("/api/community/posts/$public->id/comments")->assertJsonCount(
            0,
            "data.items"
        );
        $this->postJson("/api/community/reports", [
            "reportable_type" => "comment",
            "reportable_id" => $comment,
            "reason" => "other"
        ])->assertForbidden();
        $aPost = $this->story($a, $c);
        Sanctum::actingAs($b);
        $this->getJson("/api/community/posts/$aPost->id")->assertForbidden();
        $this->postJson(
            "/api/community/posts/$aPost->id/comments",
            $this->text()
        )->assertForbidden();
        Sanctum::actingAs($a);
        $this->deleteJson("/api/users/$b->id/block")->assertOk();
        $this->getJson("/api/community/posts/$p->id")->assertOk();
    }

    public function test_reactions_comments_notifications_and_opt_out(): void
    {
        $c = $this->community();
        $owner = $this->user();
        $reader = $this->user();
        $this->member($reader, $c);
        $p = $this->story($owner, $c);
        Sanctum::actingAs($reader);
        foreach (["support", "thanks", "encouragement"] as $reaction) {
            $this->postJson("/api/community/posts/$p->id/reactions", ["reaction_type" => $reaction])
                ->assertOk()
                ->assertJsonPath("data.reaction_count", 1)
                ->assertJsonPath("data.my_reaction", $reaction);
        }
        $this->assertDatabaseCount("community_reactions", 1);
        $this->assertDatabaseCount("notifications", 1);
        $id = $this->postJson("/api/community/posts/$p->id/comments", $this->text())
            ->assertCreated()
            ->json("data.id");
        Sanctum::actingAs($owner);
        $this->deleteJson("/api/community/comments/$id")->assertForbidden();
        $this->putJson("/api/community/preferences", [
            "notifications_enabled" => false
        ])->assertOk();
        $another = $this->story($owner, $c);
        Sanctum::actingAs($reader);
        $this->deleteJson("/api/community/comments/$id")->assertOk();
        $this->deleteJson("/api/community/posts/$p->id/reactions")->assertOk();
        $this->postJson(
            "/api/community/posts/$another->id/comments",
            $this->text()
        )->assertCreated();
        $this->assertDatabaseCount("notifications", 2);
        $this->assertStringNotContainsString("Hari ini", DB::table("notifications")->first()->body);
    }

    public function test_banned_members_cannot_rejoin_or_bypass_by_leaving(): void
    {
        $c = $this->community();
        $u = $this->user();
        $this->member($u, $c, "member", "banned");
        Sanctum::actingAs($u);
        $this->deleteJson("/api/communities/$c->id/leave")->assertOk();
        $this->postJson("/api/communities/$c->id/join", [
            "display_name" => "Uji",
            "rules_accepted" => true
        ])->assertForbidden();
        $this->getJson("/api/communities/$c->id")->assertForbidden();
        $this->getJson("/api/communities")->assertJsonCount(0, "data.items");
        $this->getJson("/api/community/my-communities")->assertJsonPath(
            "data.items.0.membership_status",
            "banned"
        );
    }

    public function test_images_are_private_held_and_cleaned_up_with_account(): void
    {
        $c = $this->community();
        $u = $this->user();
        $reader = $this->user();
        $this->member($u, $c);
        Sanctum::actingAs($u);
        $id = $this->post("/api/communities/$c->id/posts", [
            "content" => "Cerita dengan foto.",
            "sharing_acknowledged" => "1",
            "image" => UploadedFile::fake()->image("photo.jpg", 20, 20)
        ])
            ->assertCreated()
            ->assertJsonPath("data.moderation_status", "pending")
            ->json("data.id");
        $image = $this->getJson("/api/community/posts/$id/image")
            ->assertOk()
            ->assertJsonPath("data.mime_type", "image/png");
        $path = CommunityPost::findOrFail($id)->image_path;
        $this->assertStringNotContainsString(
            $image->json("data.base64"),
            Storage::disk("local")->get($path)
        );
        Sanctum::actingAs($reader);
        $this->getJson("/api/community/posts/$id/image")->assertForbidden();
        $this->getJson("/api/community/posts/$id/image?review=1")->assertForbidden();
        Sanctum::actingAs($u);
        $this->deleteJson("/api/me", ["password" => "synthetic-community-password"])->assertOk();
        Storage::disk("local")->assertMissing($path);
    }

    public function test_only_explicit_preferences_reach_recommendation_and_no_private_profile_leaks(): void
    {
        $c = $this->community();
        $u = $this->user();
        Sanctum::actingAs($u);
        $this->getJson("/api/community/home")->assertOk();
        Http::assertNothingSent();
        $this->putJson("/api/community/preferences", [
            "recommendation_enabled" => true,
            "interests" => [
                "cancer_type" => "kanker payudara",
                "support_preferences" => ["dukungan emosional"]
            ]
        ])->assertOk();
        Http::fake([
            "*" => Http::response([
                "recommendations" => [
                    ["community_id" => $c->id, "score" => 0.9, "reason" => "Pilihanmu sesuai."],
                    ["community_id" => "hallucinated", "score" => 1, "reason" => "Harus dibuang."]
                ]
            ])
        ]);
        $this->getJson("/api/community/home")->assertOk()->assertJsonCount(1, "data.recommended");
        Http::assertSent(
            fn($r) => $r["patient_context"] === [
                "cancer_type" => "kanker payudara",
                "support_preferences" => ["dukungan emosional"]
            ] &&
                !isset($r["context"]) &&
                !isset($r["user_id"])
        );
        $this->putJson("/api/community/preferences", ["recommendation_enabled" => false])
            ->assertOk()
            ->assertJsonPath("data.interests", []);
        $p = $this->story($u, $c);
        $body = $this->getJson("/api/community/posts/$p->id")
            ->assertOk()
            ->getContent();
        $this->assertStringNotContainsString($u->email, $body);
        $this->assertStringNotContainsString("Private account name", $body);
    }

    public function test_catalogue_seed_is_idempotent_without_demo_accounts(): void
    {
        $this->seed(CommunitySeeder::class);
        $this->seed(CommunitySeeder::class);
        $this->assertDatabaseCount("communities", 5);
        $this->assertDatabaseCount("users", 0);
        $this->assertDatabaseCount("community_posts", 0);
    }
}
