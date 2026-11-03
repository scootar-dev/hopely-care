<?php
namespace Tests\Feature;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
class KnowledgeWorkflowTest extends TestCase
{
    use RefreshDatabase;
    private function staff(string $name): User
    {
        $u = new User();
        $u->forceFill(['name' => $name, 'email' => $name.'@test.invalid', 'password' => 'synthetic-password', 'role' => 'CONTENT_ADMIN'])->save();
        return $u;
    }
    public function test_independent_review_publication_and_failed_withdrawal(): void
    {
        Http::preventStrayRequests();
        $author = $this->staff('author');
        $reviewer = $this->staff('reviewer');
        Sanctum::actingAs($author);
        $row = $this->postJson('/api/admin/knowledge/documents', [
            'source_id' => 'synthetic', 'title' => 'Synthetic reference', 'publisher' => 'Test',
            'document_version' => '1', 'text' => 'Synthetic educational text for testing only.',
        ])->assertCreated()->json('data');
        $path = '/api/admin/knowledge/documents/'.$row['id'];
        $this->postJson($path.'/publish', ['revision' => 1])->assertConflict();
        $this->postJson($path.'/review', ['revision' => 1])->assertForbidden();
        Sanctum::actingAs($reviewer);
        $this->postJson($path.'/review', ['revision' => 1])->assertOk();
        $this->postJson($path.'/publish', ['revision' => 1])->assertConflict();
        $this->postJson($path.'/publish', ['revision' => 2])->assertOk()->assertJsonPath('data.status', 'published');
        Http::assertNothingSent();
        \App\Models\KnowledgeDocument::whereKey($row['id'])->update(['indexed' => true]);
        config(['services.ai.key' => str_repeat('x', 32), 'services.ai.url' => 'http://ai.test']);
        Http::fake(['*' => Http::sequence()->push([], 503)->push(['removed' => true], 200)]);
        $this->postJson($path.'/unpublish', ['revision' => 3])->assertStatus(503);
        $this->assertDatabaseHas('knowledge_documents', ['id' => $row['id'], 'status' => 'published', 'revision' => 3]);
        $this->postJson($path.'/unpublish', ['revision' => 3])->assertOk()->assertJsonPath('data.status', 'draft');
    }
    public function test_import_legacy_articles_is_idempotent_and_requires_distinct_reviewer(): void
    {
        $author = $this->staff('legacy-author');
        $prior = $this->staff('legacy-prior');
        $disk = \Illuminate\Support\Facades\Storage::fake('local');
        $disk->put('knowledge-articles/'.hash('sha256', 'legacy-a').'.json', json_encode([
            'source_id' => 'legacy-a', 'title' => 'Legacy reviewed piece', 'publisher' => 'Old Source',
            'document_version' => '1.0', 'text' => 'Synthetic clinical education text.', 'reviewed' => true,
        ]));
        $disk->put('knowledge-articles/'.hash('sha256', 'legacy-b').'.json', json_encode([
            'source_id' => 'legacy-b', 'title' => 'Legacy draft piece', 'publisher' => 'Old Source',
            'document_version' => '1.0', 'text' => 'Synthetic draft education text.', 'reviewed' => false,
        ]));
        $disk->put('knowledge-articles/'.hash('sha256', 'broken').'.json', json_encode(['title' => 'Incomplete']));
        $this->artisan('knowledge:migrate-legacy', ['--author-email' => $author->email])->assertExitCode(0);
        $this->assertDatabaseHas('knowledge_documents', [
            'source_id' => 'legacy-a', 'status' => 'reviewed', 'author_id' => $author->id, 'reviewer_id' => $prior->id,
        ]);
        $this->assertDatabaseHas('knowledge_documents', [
            'source_id' => 'legacy-b', 'status' => 'draft', 'reviewer_id' => null,
        ]);
        $this->artisan('knowledge:migrate-legacy', ['--author-email' => $author->email])->assertExitCode(0);
        $this->assertSame(2, \App\Models\KnowledgeDocument::count());
    }
}
