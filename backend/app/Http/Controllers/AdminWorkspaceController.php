<?php
namespace App\Http\Controllers;

use App\Models\{User, SupportActivity, Community, CommunityReport, SupportAlert, AuditLog};
use App\Services\AuditService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AdminWorkspaceController extends Controller
{
    public const ROLES = ['ADMIN', 'SUPER_ADMIN', 'CONTENT_ADMIN', 'COMMUNITY_MODERATOR'];

    public function login(Request $r)
    {
        $v = $r->validate(['email' => 'required|email|max:254', 'password' => 'required|string']);
        $user = User::where('email', strtolower(trim($v['email'])))->first();
        abort_unless($user && Hash::check($v['password'], $user->password), 401);
        abort_unless(in_array($user->role, self::ROLES, true), 403);
        app(AuditService::class)->record($user->id, 'admin.login', 'user', $user->id);
        return $this->ok(['user' => $user, 'token' => $user->createToken('admin')->plainTextToken]);
    }

    private function authorizeModule(Request $r, string $module): void
    {
        $allowed = match ($r->user()->role) {
            'ADMIN', 'SUPER_ADMIN' => ['activities', 'communities', 'reports', 'users', 'support-alerts', 'audit'],
            'CONTENT_ADMIN' => ['activities'],
            'COMMUNITY_MODERATOR' => ['communities', 'reports'],
            default => [],
        };
        abort_unless(in_array($module, $allowed, true), 403);
    }

    public function index(Request $r, string $module)
    {
        $this->authorizeModule($r, $module);
        $v = $r->validate(['page' => 'sometimes|integer|min:1', 'search' => 'nullable|string|max:100']);
        [$model, $columns, $search] = match ($module) {
            'activities' => [SupportActivity::class, ['*'], 'title'],
            'communities' => [Community::class, ['*'], 'name'],
            'reports' => [CommunityReport::class, ['*'], 'reason'],
            'users' => [User::class, ['id', 'name', 'email', 'role', 'created_at'], 'name'],
            'support-alerts' => [SupportAlert::class, ['id', 'status', 'type', 'created_at', 'acknowledged_at', 'resolved_at'], 'status'],
            'audit' => [AuditLog::class, ['id', 'actor_user_id', 'event', 'resource_type', 'resource_id', 'created_at'], 'event'],
        };
        $query = $model::query()->select($columns);
        if ($module === 'communities') {
            $query->withCount(['members as active_members_count' => fn ($q) => $q->where('status', 'active')]);
        }
        if (!empty($v['search'])) $query->where($search, 'like', '%'.$v['search'].'%');
        return $this->ok($query->latest()->paginate(25));
    }
}
