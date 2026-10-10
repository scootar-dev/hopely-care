<?php
namespace App\Http\Controllers;

use App\Services\ProfilePhotoService;
use Illuminate\Http\Request;

class ProfilePhotoController extends Controller
{
    public function show(Request $request, ProfilePhotoService $photos)
    {
        return $this->ok($photos->read($request->user()))
            ->header("Cache-Control", "private, no-store");
    }

    public function store(Request $request, ProfilePhotoService $photos)
    {
        $request->validate([
            "photo" => [
                "required", "file", "image", "mimes:jpg,jpeg,png,webp",
                "max:2048", "dimensions:max_width=4096,max_height=4096",
            ],
        ]);
        return $this->ok($photos->replace($request->user(), $request->file("photo")))
            ->header("Cache-Control", "private, no-store");
    }

    public function destroy(Request $request, ProfilePhotoService $photos)
    {
        $photos->delete($request->user());
        return $this->ok()->header("Cache-Control", "private, no-store");
    }
}
