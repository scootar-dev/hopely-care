<?php
namespace App\Http\Controllers;

use App\Models\{Community, CommunityComment, CommunityPost, CommunityReaction};
use App\Http\Requests\CommunityContentRequest;
use App\Http\Resources\{CommunityPostResource, CommunityCommentResource};
use App\Services\{CommunityService, CommunityModerationService, CommunityMediaService};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\{DB, Gate};

class CommunityContentController extends Controller
{
    public function __construct(
        private CommunityService $service,
        private CommunityModerationService $moderation,
        private CommunityMediaService $media
    ) {}

    public function index(Request $r, ?Community $community = null)
    {
        if ($community) {
            Gate::authorize("view", $community);
        }
        $q = $this->service->posts($r->user());
        if ($community) {
            $q->where("community_id", $community->id);
        }
        if ($r->boolean("mine")) {
            $q->where("user_id", $r->user()->id);
        }
        $page = $this->service->postDetails($q, $r->user())->latest()->orderBy("id")->paginate(20);
        return $this->ok([
            "items" => CommunityPostResource::collection($page->items()),
            "page" => $page->currentPage(),
            "last_page" => $page->lastPage(),
            "total" => $page->total()
        ]);
    }

    private function postResponse(Request $r, CommunityPost $post, int $status = 200)
    {
        $data = $this->service
            ->postDetails(CommunityPost::whereKey($post->id), $r->user())
            ->firstOrFail();
        return $this->ok(new CommunityPostResource($data), $status);
    }

    public function show(Request $r, CommunityPost $post)
    {
        Gate::authorize("view", $post);
        return $this->postResponse($r, $post);
    }

    public function store(CommunityContentRequest $r, Community $community)
    {
        Gate::authorize("participate", $community);
        $v = $r->validated();
        $assessment = $this->moderation->assess("post", $v["content"], $r->hasFile("image"));
        $image = $r->hasFile("image") ? $this->media->store($r->file("image"), $r->user()) : null;
        try {
            $post = DB::transaction(function () use ($r, $community, $v, $assessment, $image) {
                $current = Community::whereKey($community->id)->lockForUpdate()->firstOrFail();
                Gate::authorize("participate", $current);
                $post = new CommunityPost();
                $post
                    ->forceFill([
                        "user_id" => $r->user()->id,
                        "community_id" => $community->id,
                        "content" => $v["content"],
                        "image_path" => $image,
                        ...$assessment
                    ])
                    ->save();
                return $post;
            });
        } catch (\Throwable $e) {
            $this->media->delete($image);
            throw $e;
        }
        return $this->postResponse($r, $post, 201);
    }

    public function update(CommunityContentRequest $r, CommunityPost $post)
    {
        Gate::authorize("update", $post);
        $v = $r->validated();
        $r->validate(["revision" => "required|integer|min:1", "image" => "prohibited"]);
        $assessment = $this->moderation->assess("post", $v["content"], $post->image_path !== null);
        DB::transaction(function () use ($r, $post, $v, $assessment) {
            Community::whereKey($post->community_id)->lockForUpdate()->firstOrFail();
            $current = CommunityPost::whereKey($post->id)->lockForUpdate()->firstOrFail();
            Gate::authorize("update", $current);
            abort_unless($current->revision === $v["revision"], 409);
            $current
                ->forceFill([
                    "content" => $v["content"],
                    "revision" => $current->revision + 1,
                    "reviewed_by" => null,
                    "reviewed_at" => null,
                    ...$assessment
                ])
                ->save();
        });
        return $this->postResponse($r, $post);
    }

    public function destroy(Request $r, CommunityPost $post)
    {
        Gate::authorize("delete", $post);
        DB::transaction(function () use ($post) {
            $current = CommunityPost::whereKey($post->id)->lockForUpdate()->firstOrFail();
            $current->delete();
        });
        $this->media->delete($post->image_path);
        return $this->ok();
    }

    public function image(Request $r, CommunityPost $post)
    {
        if ($r->boolean("review")) {
            Gate::authorize("moderate", $post->community);
        } else {
            Gate::authorize("view", $post);
        }
        return $this->ok($this->media->read($post))->header("Cache-Control", "private, no-store");
    }

    public function comments(Request $r, CommunityPost $post)
    {
        Gate::authorize("view", $post);
        $page = $this->service->comments($r->user(), $post)->oldest()->orderBy("id")->paginate(30);
        return $this->ok([
            "items" => CommunityCommentResource::collection($page->items()),
            "page" => $page->currentPage(),
            "last_page" => $page->lastPage(),
            "total" => $page->total()
        ]);
    }

    public function comment(CommunityContentRequest $r, CommunityPost $post)
    {
        Gate::authorize("view", $post);
        Gate::authorize("participate", $post->community);
        abort_unless($post->moderation_status === "approved", 403);
        $r->validate(["image" => "prohibited"]);
        $v = $r->validated();
        $assessment = $this->moderation->assess("comment", $v["content"]);
        $comment = DB::transaction(function () use ($r, $post, $v, $assessment) {
            Community::whereKey($post->community_id)->lockForUpdate()->firstOrFail();
            $current = CommunityPost::whereKey($post->id)->lockForUpdate()->firstOrFail();
            Gate::authorize("view", $current);
            Gate::authorize("participate", $current->community);
            abort_unless($current->moderation_status === "approved", 403);
            $comment = new CommunityComment();
            $comment
                ->forceFill([
                    "user_id" => $r->user()->id,
                    "post_id" => $post->id,
                    "content" => $v["content"],
                    ...$assessment
                ])
                ->save();
            return $comment;
        });
        if ($comment->moderation_status === "approved") {
            $this->service->notify($post->user_id, $r->user(), "community_comment", $post->id);
        }
        return $this->ok(
            new CommunityCommentResource($comment->load("author.communityProfile")),
            201
        );
    }

    public function deleteComment(Request $r, CommunityComment $comment)
    {
        Gate::authorize("delete", $comment);
        $comment->delete();
        return $this->ok();
    }

    public function react(Request $r, CommunityPost $post)
    {
        $v = $r->validate(["reaction_type" => "required|in:support,encouragement,thanks"]);
        DB::transaction(function () use ($r, $post, $v) {
            Community::whereKey($post->community_id)->lockForUpdate()->firstOrFail();
            $current = CommunityPost::whereKey($post->id)->lockForUpdate()->firstOrFail();
            Gate::authorize("view", $current);
            Gate::authorize("participate", $current->community);
            abort_unless($current->moderation_status === "approved", 403);
            $reaction = CommunityReaction::firstOrNew([
                "post_id" => $post->id,
                "user_id" => $r->user()->id
            ]);
            $reaction
                ->forceFill(["post_id" => $post->id, "user_id" => $r->user()->id, ...$v])
                ->save();
        });
        $this->service->notify($post->user_id, $r->user(), "community_reaction", $post->id);
        return $this->postResponse($r, $post);
    }

    public function unreact(Request $r, CommunityPost $post)
    {
        CommunityReaction::where("post_id", $post->id)->where("user_id", $r->user()->id)->delete();
        return $this->ok();
    }
}
