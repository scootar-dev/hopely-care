<?php
namespace App\Http\Controllers;
use App\Models\KnowledgeDocument;
use App\Services\AiClient;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
class KnowledgeManagementController extends Controller
{
    public function index() { return $this->ok(KnowledgeDocument::latest()->paginate(20)); }
    public function save(Request $r, ?string $id = null)
    {
        $v = $r->validate([
            'source_id' => 'required|string|max:100', 'title' => 'required|string|max:300',
            'publisher' => 'required|string|max:200', 'source_url' => 'nullable|url|max:1000',
            'published_at' => 'nullable|date', 'document_version' => 'required|string|max:80',
            'text' => 'required|string|max:200000', 'revision' => 'sometimes|integer|min:1',
        ]);
        return DB::transaction(function () use ($r, $id, $v) {
            $d = $id ? KnowledgeDocument::whereKey($id)->lockForUpdate()->firstOrFail() : new KnowledgeDocument();
            abort_if($d->exists && $d->status === 'published', 409, 'Tarik publikasi sebelum mengubah naskah.');
            abort_if($d->exists && ($v['revision'] ?? null) !== $d->revision, 409);
            abort_if(KnowledgeDocument::where('source_id', $v['source_id'])->when($id, fn ($q) => $q->where('id', '!=', $id))->exists(), 422, 'ID sumber sudah digunakan.');
            unset($v['revision']);
            $d->forceFill(['source_id' => $v['source_id'], 'document' => $v, 'status' => 'draft',
                'author_id' => $r->user()->id, 'reviewer_id' => null, 'revision' => ($d->revision ?? 0) + 1])->save();
            return $this->ok($d, $id ? 200 : 201);
        });
    }
    public function transition(Request $r, string $id, string $action, AiClient $ai)
    {
        $v = $r->validate(['revision' => 'required|integer|min:1']);
        return DB::transaction(function () use ($r, $id, $action, $ai, $v) {
            $d = KnowledgeDocument::whereKey($id)->lockForUpdate()->firstOrFail();
            abort_unless($d->revision === $v['revision'], 409);
            if ($action === 'review') {
                abort_unless($d->status === 'draft', 409);
                abort_if($d->author_id === $r->user()->id, 403, 'Peninjau harus berbeda dari penulis terakhir.');
                $d->status = 'reviewed';
                $d->reviewer_id = $r->user()->id;
            } elseif ($action === 'publish') {
                abort_unless($d->status === 'reviewed', 409);
                // Article publication remains usable independently of vector indexing.
                $d->status = 'published';
            } elseif ($action === 'index') {
                abort_unless($d->status === 'published', 409);
                $ai->post('/v1/knowledge/ingest', [...$d->document, 'reviewed' => true, 'reviewed_by' => $d->reviewer_id]);
                $d->indexed = true;
            } elseif ($action === 'unpublish') {
                abort_unless($d->status === 'published', 409);
                // Require successful index removal before declaring withdrawal complete.
                if ($d->indexed) {
                    $ai->post('/v1/knowledge/remove', ['source_id' => $d->source_id]);
                }
                Storage::disk('local')->delete('knowledge-articles/'.hash('sha256', $d->source_id).'.json');
                $d->status = 'draft';
                $d->reviewer_id = null;
                $d->indexed = false;
            } else { abort(404); }
            $d->revision++;
            $d->save();
            return $this->ok($d);
        });
    }
}
