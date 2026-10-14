<?php
namespace App\Http\Controllers;

use App\Models\{BlockedUser, Community, CommunityComment, CommunityPost, CommunityReport, User};
use App\Http\Requests\CommunityReportRequest;
use App\Services\{AuditService, CommunityService};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\{DB, Gate};

class CommunitySafetyController extends Controller
{
    public function __construct(private CommunityService $service) {}

    public function index(Request $r)
    {
        $u = $r->user();
        $reports = CommunityReport::where("reporter_user_id", $u->id)->latest()->paginate(20);
        return $this->ok([
            "guidelines" => CommunityService::GUIDELINES,
            "reports" => [
                "items" => $reports->map(fn($a) => $this->reportData($a))->all(),
                "page" => $reports->currentPage(),
                "last_page" => $reports->lastPage()
            ],
            "blocked_users" => BlockedUser::where("user_id", $u->id)
                ->with("blocked.communityProfile")
                ->get()
                ->map(
                    fn($b) => [
                        "id" => $b->blocked_user_id,
                        "display_name" => $b->blocked?->communityProfile?->display_name ?? "Anggota"
                    ]
                ),
            "can_moderate" =>
                $u->role === "ADMIN" || count($this->service->moderatorCommunityIds($u)) > 0
        ]);
    }

    private function reportData(CommunityReport $report): array
    {
        return [
            "id" => $report->id,
            "reportable_type" => $report->reportable_type,
            "reportable_id" => $report->reportable_id,
            "reason" => $report->reason,
            "status" => $report->status,
            "created_at" => $report->created_at?->toISOString()
        ];
    }

    public function report(CommunityReportRequest $r)
    {
        $v = $r->validated();
        $target = ($v["reportable_type"] === "post"
            ? CommunityPost::class
            : CommunityComment::class
        )::findOrFail($v["reportable_id"]);
        Gate::authorize("view", $target);
        $communityId =
            $target instanceof CommunityPost ? $target->community_id : $target->post->community_id;
        $report = DB::transaction(function () use ($r, $v, $communityId) {
            // Serialize reports from this user; repeated taps are idempotent.
            User::whereKey($r->user()->id)->lockForUpdate()->firstOrFail();
            $report = CommunityReport::where("reporter_user_id", $r->user()->id)
                ->where("reportable_type", $v["reportable_type"])
                ->where("reportable_id", $v["reportable_id"])
                ->first();
            if (!$report) {
                $report = new CommunityReport();
                $report
                    ->forceFill([
                        ...$v,
                        "reporter_user_id" => $r->user()->id,
                        "community_id" => $communityId
                    ])
                    ->save();
            }
            return $report;
        });
        return $this->ok($this->reportData($report), 201);
    }

    public function block(Request $r, User $user)
    {
        abort_if($user->id === $r->user()->id, 422);
        DB::transaction(function () use ($r, $user) {
            User::whereKey($r->user()->id)->lockForUpdate()->firstOrFail();
            $b = BlockedUser::firstOrNew([
                "user_id" => $r->user()->id,
                "blocked_user_id" => $user->id
            ]);
            $b->forceFill(["user_id" => $r->user()->id, "blocked_user_id" => $user->id])->save();
        });
        return $this->ok();
    }

    public function unblock(Request $r, User $user)
    {
        BlockedUser::where("user_id", $r->user()->id)
            ->where("blocked_user_id", $user->id)
            ->delete();
        return $this->ok();
    }

    public function queue(Request $r)
    {
        $v = $r->validate(["kind" => "nullable|in:post,comment,report"]);
        $kind = $v["kind"] ?? "post";
        $ids = $this->service->moderatorCommunityIds($r->user());
        abort_unless($r->user()->role === "ADMIN" || $ids, 403);
        $q = match ($kind) {
            "comment" => CommunityComment::whereHas("post")
                ->with("post.community")
                ->whereIn("moderation_status", ["pending", "flagged"]),
            "report" => CommunityReport::with("community")->whereIn("status", [
                "pending",
                "reviewed"
            ]),
            default => CommunityPost::with("community")->whereIn("moderation_status", [
                "pending",
                "flagged"
            ])
        };
        if ($r->user()->role !== "ADMIN") {
            if ($kind === "comment") {
                $q->whereHas(
                    "post.community",
                    fn($c) => $c->where("is_active", true)->whereIn("id", $ids)
                );
            } else {
                $q->whereHas(
                    "community",
                    fn($c) => $c->where("is_active", true)->whereIn("id", $ids)
                );
            }
        }
        $page = $q->oldest()->orderBy("id")->paginate(20);
        $items = $page
            ->map(function ($item) use ($kind, $r) {
                if ($kind === "report") {
                    $target = ($item->reportable_type === "post"
                        ? CommunityPost::class
                        : CommunityComment::class
                    )::find($item->reportable_id);
                    return [
                        ...$this->reportData($item),
                        "kind" => "report",
                        "community_name" => $item->community->name,
                        "content" => $target?->content ?? "Konten telah dihapus.",
                        "description" => $item->description,
                        "revision" => $target?->revision,
                        "post_id" =>
                            $target instanceof CommunityPost ? $target->id : $target?->post_id,
                        "has_image" =>
                            $target instanceof CommunityPost && $target->image_path !== null
                    ];
                }
                return [
                    "id" => $item->id,
                    "kind" => $kind,
                    "content" => $item->content,
                    "community_name" => ($kind === "post"
                        ? $item->community
                        : $item->post->community
                    )->name,
                    "moderation_status" => $item->moderation_status,
                    "revision" => $item->revision,
                    "can_approve" => $item->user_id !== $r->user()->id,
                    "has_image" => $kind === "post" && $item->image_path !== null,
                    "post_id" => $kind === "post" ? $item->id : $item->post_id,
                    "created_at" => $item->created_at?->toISOString()
                ];
            })
            ->all();
        return $this->ok([
            "items" => $items,
            "page" => $page->currentPage(),
            "last_page" => $page->lastPage()
        ]);
    }

    public function review(Request $r, string $kind, string $id)
    {
        abort_unless(in_array($kind, ["post", "comment", "report"], true), 404);
        $v = $r->validate([
            "action" => "required|in:approve,remove,dismiss",
            "revision" => "nullable|integer|min:1",
            "note" => "required|string|min:3|max:500"
        ]);
        $model = match ($kind) {
            "post" => CommunityPost::class,
            "comment" => CommunityComment::class,
            default => CommunityReport::class
        };
        $initial = $model::findOrFail($id);
        $community = $kind === "comment" ? $initial->post?->community : $initial->community;
        abort_unless($community, 404);
        Gate::authorize("moderate", $community);
        $notifications = DB::transaction(function () use ($r, $model, $kind, $id, $v, $community) {
            $currentCommunity = Community::whereKey($community->id)->lockForUpdate()->firstOrFail();
            Gate::authorize("moderate", $currentCommunity);
            $item = $model::whereKey($id)->lockForUpdate()->firstOrFail();
            $target = $item;
            if ($kind === "report") {
                abort_unless(in_array($v["action"], ["remove", "dismiss"], true), 422);
                abort_unless(in_array($item->status, ["pending", "reviewed"], true), 409);
                $target = ($item->reportable_type === "post"
                    ? CommunityPost::class
                    : CommunityComment::class
                )
                    ::whereKey($item->reportable_id)
                    ->lockForUpdate()
                    ->first();
                $item
                    ->forceFill([
                        "status" => $v["action"] === "dismiss" ? "dismissed" : "resolved",
                        "reviewed_by" => $r->user()->id,
                        "reviewed_at" => now()
                    ])
                    ->save();
            } else {
                abort_unless(in_array($v["action"], ["approve", "remove"], true), 422);
            }
            $notifications = [];
            if ($target && $v["action"] !== "dismiss") {
                abort_unless(isset($v["revision"]) && $target->revision === $v["revision"], 409);
                if ($v["action"] === "approve") {
                    abort_if($target->user_id === $r->user()->id, 403); // Independent review, including admins.
                    if ($target instanceof CommunityComment) {
                        abort_unless($target->post?->moderation_status === "approved", 409);
                    }
                }
                $target
                    ->forceFill([
                        "moderation_status" => $v["action"] === "approve" ? "approved" : "removed",
                        "revision" => $target->revision + 1,
                        "reviewed_by" => $r->user()->id,
                        "reviewed_at" => now(),
                        "moderation_meta" => ["mode" => "human", "note" => $v["note"]]
                    ])
                    ->save();
                $notifications[] = [
                    $target->user_id,
                    "community_moderation",
                    $target->id,
                    $r->user()->id
                ];
                if ($target instanceof CommunityComment && $v["action"] === "approve") {
                    // Use the actual comment author for block/notification checks, not the moderator.
                    $notifications[] = [
                        $target->post->user_id,
                        "community_comment",
                        $target->post_id,
                        $target->user_id
                    ];
                }
            }
            if ($kind === "report") {
                $notifications[] = [
                    $item->reporter_user_id,
                    "community_report_update",
                    $item->id,
                    $r->user()->id
                ];
            }
            app(AuditService::class)->record(
                $r->user()->id,
                "community." . $v["action"],
                $kind,
                $id
            );
            return $notifications;
        });
        // Commit first; provider calls never hold database locks or send rolled-back updates.
        foreach ($notifications as [$recipient, $type, $subject, $actorId]) {
            if ($actor = User::find($actorId)) {
                $this->service->notify($recipient, $actor, $type, $subject);
            }
        }
        return $this->ok();
    }
}
