<?php
namespace App\Services;

class CommunityModerationService
{
    /**
     * Potential violations are hidden and queued for independent human review.
     * Rules must not make a final decision about a sensitive personal story.
     */
    private const REMOVE_RULES = [
        "arahan medis berbahaya" => [
            "/\b(berhenti(kan)?|stop)\s+(konsumsi|mengonsumsi|pakai|minum)?\s*(obat|obatnya|terapi|kemoterapi|kimoterapi|radioterapi)\b/u",
            "/jangan\s+(pakai|konsumsi|minum|mengonsumsi)\s+(obat|obatnya|terapi|kemoterapi|kimoterapi|radioterapi)\b/u",
            "/\b\d+[\.,]?\d*\s*(mg|ml|gr|gram|tablet|pil|kapsul)\b/u",
            "/\b(cukup|tinggal)\s+(minum|konsumsi|pakai)\s+\d+\s*(obat|pil|tablet|kapsul)\b/u",
            "/\b(resep(kan)?|dokter(kan)?\s+resep)\b.*(tanpa\s+(konsultasi|dokter))/u"
        ],
        "klaim kesembuhan atau obat mujarab" => [
            "/\b(dijamin|pasti|100%)\s+(sembuh|kesembuhan)\b/u",
            "/\bsembuh\s+total\b/u",
            "/\bobat\s+(mujarab|ajaib|sakti|herbal kanker|kanker herbal)\b/u",
            "/\b(kanker|tumor)\s+(kering|habis)\s+(dalam|dengan)\s+\d/u"
        ],
        "promosi atau penjualan" => [
            "/\b(dijual|terjual)\b/u",
            "/\bjual\s+(obat|produk|herbal|suplemen|terapi|alat)\b/u",
            "/\bbeli\s+(obat|produk|suplemen|herbal|via|sekarang)\b/u",
            "/\bobat\s+(murah|impor|online|termurah)\b/u",
            "/\b(suplemen|herbal|terapi)\s+(ajaib|hebat|menyembuhkan)\b/u",
            "/\b(gratis\s+ongkir|harga\s+promo|harga\s+spesial|diskon)\b/u",
            "/\b(ready|ready stock|pre ?order)\b.*(obat|suplemen|herbal|produk)/u"
        ],
        "permintaan uang" => [
            "/\b(minta|mohon|butuh|kirimin)\w*\s+(donasi|sumbangan|dana|uang|bantuan uang)\b/u",
            "/\bgalang\s+dana\b/u",
            "/\btransfer\s+(dana\s+)?ke\s+(rek|rekening|no|nomor)\b/u",
            "/\bno\.?\s*rek(kening)?\b|\brek(kening)?\s*:\s*\d/u",
            "/\b(saweria|koefunding|kitabisa|gopay|ovo|shopeepay)\b.*\b(kirim|transfer|donasi|scan)\b/u"
        ],
        "kata kasar atau pelecehan" => [
            "/\b(kontol|memek|ngentot|bangsat|bajingan|goblok|tolol|asu|kampret)\b/u",
            "/\b(pelecehan seksual|diperkosa| harassment)\b/u",
            "/\b(memperkosa|menyodomi)\b/u"
        ]
    ];

    /**
     * Sensitive content is hidden from members and queued for a human, because
     * these need human judgement or care rather than a mechanical removal.
     */
    private const FLAG_RULES = [
        "krisis atau bahaya pada diri sendiri" => [
            "/\bbunuh\s+diri\b|\bmembunuh\s+diri\b|\bakhiri\s+hidup|akhiri\s+hidupku/u",
            "/\b(ingin|pengen|mau)\s+mati\b/u",
            "/\b(melukai|menyayat|menyabun|membakar)\s+(diri|tangan|pergelangan|badan)\w*\b/u",
            "/\bover\s?dosis\b|\bod\s+(obat|pil)\b/u"
        ],
        "kontak di luar platform" => [
            "/https?:\/\/|www\.|wa\.me|bit\.ly|tinyurl/u",
            "/\b(whatsapp|telegram|line|facebook|instagram)\s+(saya|aku|gwb|gw)\b|\bwa\s+(saya|aku)\b/u",
            "/\bnomor\s+(hp|wa|whatsapp|telepon)\b|\bwa\b\s*[:=]\s*\d/u",
            "/\b(hp|telepon|telp|no hp)\s*[:=]\s*[\+0]\d/u",
            "/(\+62|62|08)\d{7,}/u"
        ],
        "indikasi promosi" => [
            "/\b(promo|diskon|cashback|komisi|profit)\b.*\b(komunitas|grup|group|member|anggota)\b/u",
            "/\b(lowongan|job|kerja sama|peluang usaha)\b/u",
            "/\b(join|gabung)\b.*\b(bisnis|usaha|investasi|mitra)\b/u",
            "/\bcari\s+(anggota|member|downline)\b/u"
        ]
    ];

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
            $confidence =
                is_numeric($result["confidence"] ?? null) ? (float) $result["confidence"] : null;
            $meta = ["mode" => $mode, "image_review_required" => $hasImage];
            if ($mode === "manual_review") {
                return ["moderation_status" => "pending", "moderation_meta" => $meta];
            }
            // Only validated live text moderation may auto-publish. Images always require a human.
            if (
                $status === "safe" &&
                $mode === "model" &&
                $confidence !== null &&
                $confidence >= 0.8 &&
                ($result["categories"] ?? null) === [] &&
                !$hasImage
            ) {
                return ["moderation_status" => "approved", "moderation_meta" => $meta];
            }
            if ($status === "unsafe") {
                // A model verdict hides the content pending a human decision.
                if ($confidence !== null && $confidence >= 0.75) {
                    return [
                        "moderation_status" => "flagged",
                        "moderation_meta" => [...$meta, "reason" => $result["reason"] ?? "melanggar pedoman"]
                    ];
                }
                return [
                    "moderation_status" => "flagged",
                    "moderation_meta" => [...$meta, "reason" => $result["reason"] ?? "melanggar pedoman"]
                ];
            }
            if ($mode !== "model") {
                // Mock/manual results add no real judgement; local rules decide.
                return $this->rules($type, $content, $hasImage);
            }
            // The live model is uncertain: keep for human review.
            return ["moderation_status" => "pending", "moderation_meta" => $meta];
        } catch (\Throwable $e) {
            // Provider unavailable: local rules keep the community usable instead of
            // holding every submission until a moderator happens to log in.
            return $this->rules($type, $content, $hasImage, "unavailable");
        }
    }

    public function rules(string $type, string $content, bool $hasImage, string $mode = "rules"): array
    {
        $meta = ["mode" => $mode, "image_review_required" => $hasImage];
        $text = mb_strtolower($content);
        foreach (self::REMOVE_RULES as $reason => $patterns) {
            foreach ($patterns as $pattern) {
                if (preg_match($pattern, $text)) {
                    return ["moderation_status" => "flagged", "moderation_meta" => [...$meta, "reason" => $reason]];
                }
            }
        }
        foreach (self::FLAG_RULES as $reason => $patterns) {
            foreach ($patterns as $pattern) {
                if (preg_match($pattern, $text)) {
                    return ["moderation_status" => "flagged", "moderation_meta" => [...$meta, "reason" => $reason]];
                }
            }
        }
        if ($hasImage) {
            // Rule patterns cannot judge pixels; a person still reviews the image.
            return ["moderation_status" => "pending", "moderation_meta" => $meta];
        }
        return ["moderation_status" => "approved", "moderation_meta" => $meta];
    }
}
