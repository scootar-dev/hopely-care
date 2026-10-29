<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up(): void
    {
        Schema::table('activity_recommendations', fn (Blueprint $t) => $t->timestamp('remind_at')->nullable()->index());
    }
    public function down(): void
    {
        Schema::table('activity_recommendations', fn (Blueprint $t) => $t->dropColumn('remind_at'));
    }
};
