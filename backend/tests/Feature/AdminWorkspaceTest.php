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
    public function test_admin_uses_website_login_instead_of_mobile_login(): void
    {
        $u = $this->account('ADMIN');
        $this->get('/admin')->assertOk()->assertSee('Masuk admin');
        $this->postJson('/api/auth/login', ['email' => $u->email, 'password' => 'test-password-123'])->assertForbidden();
        $this->postJson('/api/admin/auth/login', ['email' => $u->email, 'password' => 'test-password-123'])->assertOk();
    }
    public function test_default_admin_seeder_preserves_existing_password(): void
    {
        $this->seed(\Database\Seeders\AdminSeeder::class);
        $u = User::where('email', 'admin@hopely.care')->firstOrFail();
        $this->assertSame('ADMIN', $u->role);
        $this->assertTrue(\Illuminate\Support\Facades\Hash::check('HopelyAdmin123!', $u->password));
        $u->password = 'changed-password-123';
        $u->save();
        $this->seed(\Database\Seeders\AdminSeeder::class);
        $this->assertTrue(\Illuminate\Support\Facades\Hash::check('changed-password-123', $u->fresh()->password));
        $this->assertSame(1, User::where('email', 'admin@hopely.care')->count());
    }
    public function test_admin_can_create_and_deactivate_community(): void
    {
        Sanctum::actingAs($this->account('ADMIN'));
        $payload = ['name' => 'Ruang dukungan', 'slug' => 'ruang-dukungan', 'description' => 'Tempat berbagi pengalaman', 'category' => 'support', 'is_active' => true];
        $id = $this->postJson('/api/admin/communities', $payload)->assertOk()->assertJsonPath('data.active_members_count', 0)->json('data.id');
        $this->putJson('/api/admin/communities/'.$id, [...$payload, 'is_active' => false])->assertOk()->assertJsonPath('data.is_active', false);
        $this->getJson('/api/admin/workspace/communities')->assertOk()->assertJsonPath('data.data.0.active_members_count', 0);
        Sanctum::actingAs($this->account('PATIENT'));
        $this->postJson('/api/admin/communities', $payload)->assertForbidden();
    }
}
