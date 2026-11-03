<?php
namespace App\Console\Commands;

use App\Models\{KnowledgeDocument, User};
use App\Services\AuditService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class KnowledgeMigrateLegacy extends Command
{
    protected $signature = "knowledge:migrate-legacy
        {--author-email= : Account email recorded as the author of imported documents}
        {--reviewer-email= : Account email recorded as the reviewer of pre-reviewed articles}";

    protected $description = "Import legacy reviewed article files from knowledge-articles into the knowledge_documents review workflow";

    private const KNOWLEDGE_ROLES = ['ADMIN', 'SUPER_ADMIN', 'CONTENT_ADMIN'];

    public function handle(): int
    {
        $author = $this->resolveAuthor();
        if (!$author) {
            $this->error("Author account not found. Provide --author-email= or create an admin/super admin account first.");
            return self::FAILURE;
        }
        $disk = Storage::disk('local');
        $files = collect($disk->files('knowledge-articles'))
            ->filter(fn (string $f): bool => preg_match('/^[a-f0-9]{64}\.json$/', basename($f)) === 1)
            ->values();
        if ($files->isEmpty()) {
            $this->info('No migration candidates under local storage knowledge-articles. Knowledge remains managed by knowledge_documents.');
            return self::SUCCESS;
        }
        $imported = 0;
        $skipped = 0;
        $invalid = 0;
        foreach ($files as $file) {
            $name = pathinfo($file, PATHINFO_FILENAME);
            $raw = $disk->get($file);
            $row = json_decode($raw, true, 512, JSON_THROW_ON_ERROR);
            if (!is_array($row)) {
                $invalid++;
                $this->warn("Skipped unparseable file $name.");
                continue;
            }
            $sourceId = trim((string) ($row['source_id'] ?? ''));
            $title = trim((string) ($row['title'] ?? ''));
            $publisher = trim((string) ($row['publisher'] ?? ''));
            $text = (string) ($row['text'] ?? '');
            if ($sourceId === '' || $title === '' || $publisher === '' || $text === '') {
                $invalid++;
                $this->warn("Skipped $name: missing source_id, title, publisher, or text.");
                continue;
            }
            if (KnowledgeDocument::where('source_id', $sourceId)->exists()) {
                $skipped++;
                continue;
            }
            $doc = [
                'source_id' => $sourceId,
                'title' => $title,
                'publisher' => $publisher,
                'text' => $text,
                'document_version' => trim((string) ($row['document_version'] ?? '')) ?: 'legacy',
                'source_url' => $row['source_url'] ?? null,
                'published_at' => $row['published_at'] ?? null,
            ];
            $sourceUrl = $doc['source_url'] ?? '';
            if (is_string($sourceUrl) && $sourceUrl !== '' && filter_var($sourceUrl, FILTER_VALIDATE_URL) === false) {
                $this->warn("Dropped invalid source_url on $name.");
                unset($doc['source_url']);
            }
            $status = 'draft';
            $reviewerId = null;
            if (($row['reviewed'] ?? false) === true) {
                $reviewer = $this->resolveReviewer($author);
                if ($reviewer) {
                    $status = 'reviewed';
                    $reviewerId = $reviewer->id;
                } else {
                    $this->warn("Imported $sourceId as draft: no distinct reviewer account is available to reconfirm the prior review.");
                }
            }
            $document = new KnowledgeDocument();
            $document->forceFill([
                'source_id' => $sourceId,
                'document' => $doc,
                'status' => $status,
                'indexed' => false,
                'author_id' => $author->id,
                'reviewer_id' => $reviewerId,
                'revision' => 1,
            ])->save();
            $imported++;
        }
        app(AuditService::class)->record($author->id, 'knowledge.legacy_articles_imported', 'knowledge');
        $this->table(['imported', 'previously_reviewed', 'already_managed', 'skipped-invalid'], [
            [$imported, $imported, $skipped, $invalid],
        ]);
        $this->info("Imported $imported legacy editorial article file(s). Review the content before publishing; re-index to RAG from the admin panel if needed.");
        return self::SUCCESS;
    }

    private function resolveAuthor(): ?User
    {
        $email = trim((string) $this->option('author-email'));
        if ($email !== '') {
            return User::where('email', $email)->whereIn('role', self::KNOWLEDGE_ROLES)->first();
        }
        return User::whereIn('role', self::KNOWLEDGE_ROLES)->orderBy('created_at')->first();
    }

    private function resolveReviewer(User $author): ?User
    {
        $email = trim((string) $this->option('reviewer-email'));
        if ($email !== '') {
            return User::where('email', $email)->whereIn('role', self::KNOWLEDGE_ROLES)->where('id', '!=', $author->id)->first();
        }
        return User::whereIn('role', self::KNOWLEDGE_ROLES)->where('id', '!=', $author->id)->orderBy('created_at')->first();
    }
}
