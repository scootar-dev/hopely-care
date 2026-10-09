<?php
namespace App\Http\Controllers;
use App\Http\Requests\RecordRequest;
use App\Http\Resources\RecordResource;
use App\Services\RecordService;
use Illuminate\Http\Request;
class RecordController extends Controller
{
    public function __construct(private RecordService $records) {}
    public function index(Request $r)
    {
        $items = $this->records
            ->model($r->route("kind"))
            ::where("user_id", $r->user()->id)
            ->orderByDesc("created_at")
            ->paginate(30);
        return $this->ok([
            "items" => RecordResource::collection($items->items()),
            "page" => $items->currentPage(),
            "last_page" => $items->lastPage(),
            "total" => $items->total()
        ]);
    }
    public function show(Request $r)
    {
        return $this->ok(
            new RecordResource($this->records->owned($r->route("kind"), $r->route("id")))
        );
    }
    public function store(RecordRequest $r)
    {
        return $this->ok(
            new RecordResource(
                $this->records->save($r->user()->id, $r->route("kind"), $r->validated())
            ),
            201
        );
    }
    public function update(RecordRequest $r)
    {
        return $this->ok(
            new RecordResource(
                $this->records->save(
                    $r->user()->id,
                    $r->route("kind"),
                    $r->validated(),
                    $r->route("id")
                )
            )
        );
    }
    public function destroy(Request $r)
    {
        $m = $this->records->owned($r->route("kind"), $r->route("id"));
        $m->delete();
        return $this->ok();
    }
}
