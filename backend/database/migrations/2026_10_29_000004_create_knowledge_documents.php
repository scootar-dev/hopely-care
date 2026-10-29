<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up(): void
    {
        Schema::create('knowledge_documents', function (Blueprint $t) {
            $t->uuid('id')->primary();
            $t->string('source_id', 100)->unique();
            $t->json('document');
            $t->string('status')->default('draft');
            $t->boolean('indexed')->default(false);
            $t->foreignUuid('author_id')->constrained('users');
            $t->foreignUuid('reviewer_id')->nullable()->constrained('users');
            $t->unsignedInteger('revision')->default(1);
            $t->timestamps();
        });
    }
    public function down(): void { Schema::dropIfExists('knowledge_documents'); }
};
