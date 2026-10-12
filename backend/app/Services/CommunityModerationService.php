<?php
namespace App\Services;

class CommunityModerationService
{
    public function assess(string $type, string $content, bool $hasImage = false): array
    {
        try {
            $result = app(AiClient::class)->post(
                "/v1/ai/community/moderate",
                [
                    "content_type" => $type,
                    "content" => $content
                ],
                40
            );
            $status = $result["status"] ?? "review";
            $mode = $result["mode"] ?? "unavailable";
            // Only validated live text moderation may auto-publish. Images always require a human.
            $approved =
                $status === "safe" &&
                $mode === "model" &&
                is_numeric($result["confidence"] ?? null) &&
                $result["confidence"] >= 0.8 &&
                ($result["categories"] ?? null) === [] &&
                !$hasImage;
            return [
                "moderation_status" => $approved
                    ? "approved"
                    : ($status === "unsafe"
                        ? "flagged"
                        : "pending"),
                "moderation_meta" => [
                    "mode" => in_array($mode, ["model", "rules", "manual_review"], true)
                        ? $mode
                        : "unavailable",
                    "image_review_required" => $hasImage
                ]
            ];
        } catch (\Throwable $e) {
            return [
                "moderation_status" => "pending",
                "moderation_meta" => ["mode" => "unavailable", "image_review_required" => $hasImage]
            ];
        }
    }
}
