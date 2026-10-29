<?php
namespace App\Http\Controllers;

use Illuminate\Support\Facades\Storage;

class KnowledgeArticleController extends Controller
{
    public function index()
    {
        $disk = Storage::disk('local');
        $items = [];
        foreach (\App\Models\KnowledgeDocument::where('status', 'published')->get() as $document) {
            $row = $document->document;
            $items[] = ['id' => $document->id, 'title' => $row['title'], 'publisher' => $row['publisher']];
        }
        foreach ($disk->files('knowledge-articles') as $file) {
            $row = json_decode($disk->get($file), true, 512, JSON_THROW_ON_ERROR);
            if (!($row['reviewed'] ?? false)) continue;
            if (\App\Models\KnowledgeDocument::where('source_id', $row['source_id'] ?? '')->exists()) continue;
            $items[] = ['id' => pathinfo($file, PATHINFO_FILENAME), 'title' => $row['title'], 'publisher' => $row['publisher']];
        }
        return $this->ok(['items' => $items]);
    }
    public function show(string $id)
    {
        if (\Illuminate\Support\Str::isUuid($id)) {
            $document = \App\Models\KnowledgeDocument::where('status', 'published')->findOrFail($id);
            return $this->ok(['id' => $id, ...$document->document]);
        }
        abort_unless(preg_match('/^[a-f0-9]{64}$/', $id), 404);
        $disk = Storage::disk('local');
        $path = "knowledge-articles/$id.json";
        abort_unless($disk->exists($path), 404);
        $row = json_decode($disk->get($path), true, 512, JSON_THROW_ON_ERROR);
        $managed = \App\Models\KnowledgeDocument::where('source_id', $row['source_id'] ?? '')->first();
        if ($managed) {
            abort_unless($managed->status === 'published', 404);
            return $this->ok(['id' => $managed->id, ...$managed->document]);
        }
        abort_unless($row['reviewed'] ?? false, 404);
        return $this->ok(['id' => $id, ...$row]);
    }
}
