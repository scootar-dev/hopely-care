<?php
namespace Tests\Feature;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminWorkspaceTest extends TestCase
{
    use RefreshDatabase;
    private function account(string $role): User
    {
        $user = new User;
        $user->forceFill(['name'=>'Admin test', 'email'=>uniqid().'@test.invalid', 'password'=>'test-password-123', 'role'=>$role])->save();
        return $user;
    }
    public function test_patient_and_caregiver_cannot_login_to_admin_or_read_workspace(): void
    {
        foreach (['PATIENT', 'CAREGIVER'] as $role) {
            $u = $this->account($role);
            $this->postJson('/api/admin/auth/login', ['email'=>$u->email, 'password'=>'test-password-123'])->assertForbidden();
            Sanctum::actingAs($u);
            $this->getJson('/api/admin/workspace/users')->assertForbidden();
        }
    }
    public function test_existing_admin_can_login_and_read_safe_paginated_accounts(): void
    {
        $u = $this->account('ADMIN');
        $this->postJson('/api/admin/auth/login', ['email'=>$u->email, 'password'=>'test-password-123'])->assertOk();
        Sanctum::actingAs($u);
        $this->getJson('/api/admin/workspace/users')->assertOk()->assertJsonPath('data.per_page',25)->assertJsonMissingPath('data.data.0.password');
        $this->assertDatabaseHas('audit_logs', ['event'=>'admin.login', 'actor_user_id'=>$u->id]);
        $this->getJson('/api/admin/workspace/journals')->assertForbidden();
    }
}
