<?php
namespace App\Http\Controllers;
use App\Models\Community;
use App\Services\AuditService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminCommunityController extends Controller
{
    public function save(Request $r, ?string $id = null)
    {
        $community = $id ? Community::findOrFail($id) : new Community();
        $v = $r->validate([
            'name' => 'required|string|max:100',
            'slug' => ['required', 'string', 'max:120', 'regex:/^[a-z0-9]+(?:-[a-z0-9]+)*$/', Rule::unique('communities')->ignore($community->id)],
            'description' => 'required|string|max:5000',
            'category' => 'required|string|max:40',
            'cancer_type' => 'nullable|string|max:100',
            'treatment_phase' => 'nullable|string|max:100',
            'support_type' => 'nullable|string|max:100',
            'image_url' => 'nullable|url:https|max:255',
            'is_active' => 'required|boolean',
        ]);
        $community->fill($v)->save();
        app(AuditService::class)->record($r->user()->id, $id ? 'community.updated' : 'community.created', 'community', $community->id);
        return $this->ok($community->loadCount(['members as active_members_count' => fn ($q) => $q->where('status', 'active')]));
    }
}
