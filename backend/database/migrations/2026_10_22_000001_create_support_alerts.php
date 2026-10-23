<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up(): void
    {
        Schema::create('support_alerts', function (Blueprint $t) {
            $t->uuid('id')->primary();
            $t->foreignUuid('patient_id')->constrained('users');
            $t->string('type')->default('EMERGENCY_SUPPORT');
            $t->string('status')->default('ACTIVE');
            $t->foreignUuid('acknowledged_by')->nullable()->constrained('users');
            $t->timestamp('acknowledged_at')->nullable();
            $t->timestamp('resolved_at')->nullable();
            $t->timestamps();
            $t->index(['patient_id', 'status']);
        });
        Schema::create('support_alert_recipients', function (Blueprint $t) {
            $t->foreignUuid('alert_id')->constrained('support_alerts');
            $t->foreignUuid('caregiver_id')->constrained('users');
            $t->primary(['alert_id', 'caregiver_id']);
        });
    }
    public function down(): void
    {
        Schema::dropIfExists('support_alert_recipients');
        Schema::dropIfExists('support_alerts');
    }
};
