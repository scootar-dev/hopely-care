<?php
namespace App\Services;

use App\Models\{
    BlockedUser,
    Community,
    CommunityComment,
    CommunityMember,
    CommunityPost,
    CommunityPreference,
    User
};
use Illuminate\Database\Eloquent\Builder;

class CommunityService
{
    public const GUIDELINES = [
        "Berbagi pengalaman dan dukungan dengan hormat. Setiap perjalanan berbeda.",
        "Jangan memberi diagnosis, resep, dosis, klaim kesembuhan, atau menyuruh menghentikan perawatan.",
        "Hindari promosi obat, terapi tanpa dasar, penipuan, dan permintaan uang.",
        "Bagikan hanya informasi yang kamu pilih sendiri. Minta izin sebelum membagikan foto atau cerita orang lain.",
        "Laporkan konten yang mengkhawatirkan. Moderator dapat menahan atau menghapus publikasi.",
        "Komunitas bukan layanan darurat dan informasi anggotanya tidak menggantikan tenaga kesehatan."
    ];

    public function blockedIds(User $user): array
    {
        return BlockedUser::where("user_id", $user->id)
            ->pluck("blocked_user_id")
            ->merge(BlockedUser::where("blocked_user_id", $user->id)->pluck("user_id"))
            ->unique()
            ->all();
    }

    public function communities(User $user): Builder
    {
        return Community::where("is_active", true)
            ->whereDoesntHave(
                "members",
                fn($q) => $q->where("user_id", $user->id)->where("status", "banned")
            )
            ->with(["members" => fn($q) => $q->where("user_id", $user->id)])
            ->withCount([
                "members" => fn($q) => $q->where("status", "active"),
                "posts" => fn($q) => $q->where("moderation_status", "approved")
            ]);
    }

    public function hydrateCommunity(Community $community, User $user): Community
    {
        return $community
            ->load(["members" => fn($q) => $q->where("user_id", $user->id)])
            ->loadCount([
                "members" => fn($q) => $q->where("status", "active"),
                "posts" => fn($q) => $q->where("moderation_status", "approved")
            ]);
    }

    public function posts(User $user): Builder
    {
        return CommunityPost::where(
            fn($scope) => $scope
                ->whereHas(
                    "community",
                    fn($q) => $q
                        ->where("is_active", true)
                        ->whereDoesntHave(
                            "members",
                            fn($m) => $m->where("user_id", $user->id)->where("status", "banned")
                        )
                )
                ->orWhere("user_id", $user->id)
        )
            ->whereNotIn("user_id", $this->blockedIds($user))
            ->where(
                fn($q) => $q
                    ->where("moderation_status", "approved")
                    ->orWhere(
                        fn($own) => $own
                            ->where("user_id", $user->id)
                            ->whereIn("moderation_status", ["pending", "flagged", "removed"])
                    )
            );
    }

    public function postDetails(Builder $query, User $user): Builder
    {
        $blocked = $this->blockedIds($user);
        return $query
            ->with([
                "author.communityProfile",
                "community",
                "reactions" => fn($q) => $q->where("user_id", $user->id)
            ])
            ->withCount([
                "reactions" => fn($q) => $q->whereNotIn("user_id", $blocked),
                "comments" => fn($q) => $q
                    ->whereNotIn("user_id", $blocked)
                    ->where("moderation_status", "approved")
            ]);
    }

    public function comments(User $user, CommunityPost $post): Builder
    {
        return $post
            ->comments()
            ->getQuery()
            ->whereNotIn("user_id", $this->blockedIds($user))
            ->where(
                fn($q) => $q
                    ->where("moderation_status", "approved")
                    ->orWhere(
                        fn($own) => $own
                            ->where("user_id", $user->id)
                            ->whereIn("moderation_status", ["pending", "flagged"])
                    )
            )
            ->with("author.communityProfile");
    }

    public function preference(User $user): CommunityPreference
    {
        $p = CommunityPreference::firstOrNew(["user_id" => $user->id]);
        if (!$p->exists) {
            $p->forceFill([
                "user_id" => $user->id,
                "display_name" => "Anggota",
                "notifications_enabled" => true,
                "recommendation_enabled" => false
            ])->save();
        }
        return $p;
    }

    public function notify(string $recipient, User $actor, string $type, string $subject): void
    {
        if ($recipient === $actor->id || in_array($recipient, $this->blockedIds($actor), true)) {
            return;
        }
        if (
            CommunityPreference::where("user_id", $recipient)->value("notifications_enabled") ===
                false ||
            CommunityPreference::where("user_id", $recipient)->value("notifications_enabled") === 0
        ) {
            return;
        }
        // At most one notification of this type per subject and recipient each day.
        app(NotificationService::class)->send(
            $recipient,
            $type,
            "$type:$recipient:$subject:" . now()->format("Y-m-d")
        );
    }

    public function moderatorCommunityIds(User $user): array
    {
        return CommunityMember::where("user_id", $user->id)
            ->where("status", "active")
            ->whereIn("role", ["moderator", "admin"])
            ->pluck("community_id")
            ->all();
    }

    public function recommend(User $user): array
    {
        $catalogue = $this->communities($user)
            ->orderByDesc("posts_count")
            ->orderBy("id")
            ->limit(200)
            ->get();
        $p = CommunityPreference::where("user_id", $user->id)->first();
        if ($p?->recommendation_enabled && $catalogue->isNotEmpty()) {
            try {
                $result = app(AiClient::class)->post(
                    "/v1/ai/community/recommend",
                    [
                        "personalization_allowed" => true,
                        // Deliberately no ContextService, patient profile, journal or chat data.
                        "patient_context" => $p->interests ?? [],
                        "communities" => $catalogue
                            ->map(
                                fn($c) => [
                                    "id" => $c->id,
                                    "name" => $c->name,
                                    "category" => $c->category,
                                    "cancer_type" => $c->cancer_type,
                                    "treatment_phase" => $c->treatment_phase,
                                    "support_type" => $c->support_type,
                                    "activity_count" => $c->posts_count
                                ]
                            )
                            ->all()
                    ],
                    8
                );
                $valid = [];
                foreach (array_slice($result["recommendations"] ?? [], 0, 6) as $row) {
                    $community = $catalogue->firstWhere("id", $row["community_id"] ?? "");
                    if (
                        $community &&
                        !isset($valid[$community->id]) &&
                        is_string($row["reason"] ?? null)
                    ) {
                        $valid[$community->id] = [
                            "community" => $community,
                            "reason" => mb_substr($row["reason"], 0, 300)
                        ];
                    }
                }
                if ($valid) {
                    return ["method" => "metadata", "items" => array_values($valid)];
                }
            } catch (\Throwable $e) {
                /* Non-essential: discovery still works without AI. */
            }
        }
        return [
            "method" => "catalogue",
            "items" => $catalogue
                ->take(4)
                ->map(
                    fn($c) => [
                        "community" => $c,
                        "reason" =>
                            "Ruang dukungan yang tersedia. Pilih yang terasa sesuai untukmu."
                    ]
                )
                ->all()
        ];
    }
}
