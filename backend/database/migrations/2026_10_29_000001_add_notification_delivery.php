<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up(): void
    {
        Schema::table('notifications', function (Blueprint $t) {
            // Provider acceptance is not proof that a device or person received a message.
            $t->string('push_status', 32)->default('pending');
            $t->unsignedInteger('push_attempts')->default(0);
            $t->timestamp('push_attempted_at')->nullable();
            $t->timestamp('push_accepted_at')->nullable();
        });
    }
    public function down(): void
    {
        Schema::table('notifications', fn (Blueprint $t) => $t->dropColumn([
            'push_status', 'push_attempts', 'push_attempted_at', 'push_accepted_at',
        ]));
    }
};
