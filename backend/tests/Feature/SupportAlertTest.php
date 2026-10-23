<?php
namespace Tests\Feature;
use App\Models\{User, CaregiverLink, CaregiverPermission};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
class SupportAlertTest extends TestCase
{
    use RefreshDatabase;
    private function user($role): User
    {
        $u = new User;
        $u->forceFill(['name'=>'Test', 'email'=>uniqid().'@test.invalid', 'password'=>'test-password', 'role'=>$role])->save();
        return $u;
    }
    private function link($p, $c, $allowed = true)
    {
        $l = CaregiverLink::create(['patient_user_id'=>$p->id, 'caregiver_user_id'=>$c->id, 'invited_email'=>$c->email, 'relationship_label'=>'Family', 'invitation_status'=>'accepted']);
        CaregiverPermission::create(['caregiver_link_id'=>$l->id, 'can_receive_support_alert'=>$allowed]);
        return $l;
    }
    public function test_lifecycle_and_multiple_recipients(): void
    {
        $p=$this->user('PATIENT'); $a=$this->user('CAREGIVER'); $b=$this->user('CAREGIVER');
        $this->link($p,$a); $this->link($p,$b);
        Sanctum::actingAs($p);
        $id=$this->postJson('/api/support-alerts')->assertCreated()->assertJsonPath('data.recipient_count',2)->json('data.id');
        $this->assertDatabaseCount('notifications',2);
        $this->postJson('/api/support-alerts')->assertJsonPath('data.id',$id);
        Sanctum::actingAs($a);
        $this->postJson("/api/support-alerts/$id/acknowledge")->assertOk()->assertJsonPath('data.status','ACKNOWLEDGED');
        Sanctum::actingAs($b);
        $this->getJson('/api/caregiver/support-alerts')->assertJsonPath('data.alerts.0.acknowledged_by',$a->id);
        $this->postJson("/api/support-alerts/$id/acknowledge")->assertConflict();
        $this->postJson("/api/support-alerts/$id/resolve")->assertOk()->assertJsonPath('data.status','RESOLVED');
        $this->assertDatabaseHas('support_alerts',['id'=>$id,'status'=>'RESOLVED']);
    }
    public function test_permission_role_validation_and_cancel(): void
    {
        $p=$this->user('PATIENT'); $a=$this->user('CAREGIVER'); $b=$this->user('CAREGIVER'); $stranger=$this->user('CAREGIVER');
        $link=$this->link($p,$a); $this->link($p,$b,false);
        Sanctum::actingAs($p);
        $this->postJson('/api/support-alerts',['patient_id'=>$a->id])->assertUnprocessable();
        $id=$this->postJson('/api/support-alerts')->assertCreated()->json('data.id');
        foreach ([$b,$stranger] as $u) {
            Sanctum::actingAs($u);
            $this->getJson('/api/caregiver/support-alerts')->assertJsonCount(0,'data.alerts');
            $this->postJson("/api/support-alerts/$id/resolve")->assertForbidden();
            $this->assertDatabaseMissing('notifications',['user_id'=>$u->id]);
        }
        Sanctum::actingAs($a);
        $this->postJson('/api/support-alerts')->assertForbidden();
        $this->postJson("/api/support-alerts/$id/cancel")->assertForbidden();
        $link->update(['invitation_status'=>'revoked']);
        $this->postJson("/api/support-alerts/$id/acknowledge")->assertForbidden();
        Sanctum::actingAs($p);
        $this->postJson("/api/support-alerts/$id/cancel")->assertOk()->assertJsonPath('data.status','RESOLVED');
    }
    public function test_no_caregiver_and_authentication(): void
    {
        $this->postJson('/api/support-alerts')->assertUnauthorized();
        Sanctum::actingAs($this->user('PATIENT'));
        $this->getJson('/api/support-alerts/active')->assertJsonPath('data.eligible_count',0);
        $this->postJson('/api/support-alerts')->assertUnprocessable();
        $this->assertDatabaseCount('support_alerts',0);
    }
}
