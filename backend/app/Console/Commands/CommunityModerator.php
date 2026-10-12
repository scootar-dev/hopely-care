<?php
namespace App\Console\Commands;

use App\Models\{Community, CommunityMember, User};
use Illuminate\Console\Command;

class CommunityModerator extends Command
{
    protected $signature = "community:moderator {email : Existing account email} {slug : Community slug}";
    protected $description = "Assign an existing account as a moderator of one Support Circle";

    public function handle(): int
    {
        $user = User::where("email", strtolower($this->argument("email")))->first();
        $community = Community::where("slug", $this->argument("slug"))
            ->where("is_active", true)
            ->first();
        if (!$user || !$community) {
            $this->error("Account or active community not found.");
            return self::FAILURE;
        }
        $member = CommunityMember::firstOrNew([
            "community_id" => $community->id,
            "user_id" => $user->id
        ]);
        $member
            ->forceFill([
                "community_id" => $community->id,
                "user_id" => $user->id,
                "role" => "moderator",
                "status" => "active",
                "joined_at" => $member->joined_at ?? now()
            ])
            ->save();
        app(\App\Services\AuditService::class)->record(
            $user->id,
            "community.moderator_assigned_via_cli",
            "community",
            $community->id
        );
        $this->info("Moderator assigned. Open Support Circle > Keamanan > Antrean moderasi.");
        return self::SUCCESS;
    }
}
