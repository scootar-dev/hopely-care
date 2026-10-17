<?php
namespace App\Http\Controllers;

use App\Models\{Community, CommunityMember, CommunityPost, CommunityReaction};
use App\Services\CommunityService;
use App\Http\Resources\{CommunityResource, CommunityPostResource};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\{DB, Gate};

class CommunityController extends Controller
{
    public function __construct(private CommunityService $service) {}

    public function index(Request $r)
    {
        $v = $r->validate([
            "search" => "nullable|string|max:100",
            "category" => "nullable|in:cancer,treatment,emotional,survivor,caregiver",
            "sort" => "nullable|in:relevant,newest,active",
            "page" => "nullable|integer|min:1"
        ]);
        $q = $this->service->communities($r->user());
        if ($search = $v["search"] ?? null) {
            $q->where("name", "like", "%" . addcslashes($search, "%_\\") . "%");
        }
        if ($category = $v["category"] ?? null) {
            $q->where("category", $category);
        }
        $sort = $v["sort"] ?? "relevant";
        if ($sort === "relevant") {
            $p = $this->service->preference($r->user());
            if ($p->recommendation_enabled) {
                foreach (["cancer_type", "treatment_phase"] as $key) {
                    if ($value = ($p->interests ?? [])[$key] ?? null) {
                        $q->orderByRaw("CASE WHEN $key = ? THEN 0 ELSE 1 END", [$value]);
                    }
                }
                $preferences = ($p->interests ?? [])["support_preferences"] ?? [];
                if ($preferences) {
                    $q->orderByRaw(
                        "CASE WHEN support_type IN (" .
                            implode(",", array_fill(0, count($preferences), "?")) .
                            ") THEN 0 ELSE 1 END",
                        $preferences
                    );
                }
            }
        }
        if ($sort === "active") {
            $q->withCount([
                "posts as recent_post_count" => fn($p) => $p
                    ->where("moderation_status", "approved")
                    ->where("created_at", ">=", now()->subDays(7))
            ])->orderByDesc("recent_post_count");
        }
        $page = $q->orderByDesc("created_at")->orderBy("id")->paginate(20);
        return $this->ok([
            "items" => CommunityResource::collection($page->items()),
            "page" => $page->currentPage(),
            "last_page" => $page->lastPage(),
            "total" => $page->total()
        ]);
    }

    public function home(Request $r)
    {
        $u = $r->user();
        $recommendations = $this->service->recommend($u);
        $shared = $this->service->posts($u)
            ->where("user_id", $u->id)
            ->where("moderation_status", "approved")
            ->where("is_demo", false);
        return $this->ok([
            "stats" => [
                "shared_posts" => (clone $shared)->count(),
                "support_received" => CommunityReaction::whereIn("post_id", (clone $shared)->select("id"))
                    ->whereNotIn("user_id", array_merge([$u->id], $this->service->blockedIds($u)))
                    ->count()
            ],
            "recommended" => array_map(
                fn($row) => [
                    "community" => new CommunityResource($row["community"]),
                    "reason" => $row["reason"]
                ],
                $recommendations["items"]
            ),
            "recommendation_method" => $recommendations["method"],
            "joined" => CommunityResource::collection(
                $this->service
                    ->communities($u)
                    ->whereHas(
                        "members",
                        fn($q) => $q->where("user_id", $u->id)->where("status", "active")
                    )
                    ->get()
            ),
            "recent" => CommunityPostResource::collection(
                $this->service
                    ->postDetails($this->service->posts($u), $u)
                    ->latest()
                    ->orderBy("id")
                    ->limit(8)
                    ->get()
            )
        ]);
    }

    public function show(Request $r, Community $community)
    {
        Gate::authorize("view", $community);
        return $this->ok([
            "community" => new CommunityResource(
                $this->service->hydrateCommunity($community, $r->user())
            ),
            "guidelines" => CommunityService::GUIDELINES
        ]);
    }

    public function join(Request $r, Community $community)
    {
        Gate::authorize("join", $community);
        $v = $r->validate([
            "rules_accepted" => "required|accepted",
            "display_name" => "required|string|min:2|max:60"
        ]);
        DB::transaction(function () use ($r, $community, $v) {
            // Serialize membership writes, including first join (unique pair remains the final guard).
            Community::whereKey($community->id)->lockForUpdate()->firstOrFail();
            Gate::authorize("join", $community->fresh());
            $m = CommunityMember::where("community_id", $community->id)
                ->where("user_id", $r->user()->id)
                ->first();
            if (!$m) {
                $m = new CommunityMember();
            }
            $m->forceFill([
                "community_id" => $community->id,
                "user_id" => $r->user()->id,
                "status" => "active",
                "role" => $m->role ?? "member",
                "joined_at" => $m->joined_at ?? now()
            ])->save();
            $this->service
                ->preference($r->user())
                ->fill(["display_name" => trim($v["display_name"])])
                ->save();
        });
        return $this->show($r, $community);
    }

    public function leave(Request $r, Community $community)
    {
        DB::transaction(function () use ($r, $community) {
            Community::whereKey($community->id)->lockForUpdate()->firstOrFail();
            CommunityMember::where("community_id", $community->id)
                ->where("user_id", $r->user()->id)
                ->where("status", "!=", "banned")
                ->update(["status" => "left", "role" => "member"]);
        });
        return $this->ok();
    }

    public function mine(Request $r)
    {
        $q = Community::with(["members" => fn($m) => $m->where("user_id", $r->user()->id)])
            ->withCount([
                "members" => fn($m) => $m->where("status", "active"),
                "posts" => fn($p) => $p->where("moderation_status", "approved")
            ])
            ->whereHas(
                "members",
                fn($m) => $m
                    ->where("user_id", $r->user()->id)
                    ->whereIn("status", ["active", "pending", "banned"])
            )
            ->orderBy("name")
            ->paginate(20);
        return $this->ok([
            "items" => CommunityResource::collection($q->items()),
            "page" => $q->currentPage(),
            "last_page" => $q->lastPage(),
            "total" => $q->total()
        ]);
    }

    public function preferences(Request $r)
    {
        $p = $this->service->preference($r->user());
        if ($r->isMethod("PUT")) {
            $v = $r->validate([
                "display_name" => "sometimes|required|string|min:2|max:60",
                "notifications_enabled" => "sometimes|required|boolean",
                "recommendation_enabled" => "sometimes|required|boolean",
                "interests" => "sometimes|array:cancer_type,treatment_phase,support_preferences",
                "interests.cancer_type" => "nullable|string|max:100",
                "interests.treatment_phase" => "nullable|string|max:100",
                "interests.support_preferences" => "sometimes|array|max:10",
                "interests.support_preferences.*" => "string|max:80"
            ]);
            $p->fill($v);
            if (!$p->recommendation_enabled) {
                $p->interests = null;
            }
            $p->save();
        }
        return $this->ok([
            "display_name" => $p->display_name,
            "notifications_enabled" => $p->notifications_enabled,
            "recommendation_enabled" => $p->recommendation_enabled,
            "interests" => $p->interests ?? (object) []
        ]);
    }
}
