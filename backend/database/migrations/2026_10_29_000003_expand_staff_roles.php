<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up(): void
    {
        Schema::table('users', fn (Blueprint $t) => $t->enum('role', [
            'PATIENT', 'CAREGIVER', 'ADMIN', 'SUPER_ADMIN', 'CONTENT_ADMIN', 'COMMUNITY_MODERATOR',
        ])->change());
    }
    public function down(): void
    {
        // Do not silently demote existing staff accounts during a rollback.
    }
};
