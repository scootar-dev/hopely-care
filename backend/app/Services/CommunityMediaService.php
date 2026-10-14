<?php
namespace App\Services;

use App\Models\{CommunityPost, User};
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\{Crypt, Storage};
use Illuminate\Support\Str;

class CommunityMediaService
{
    public function store(UploadedFile $file, User $user): string
    {
        // Re-encode to strip EXIF/location metadata before explicit sharing.
        abort_unless(function_exists("imagecreatefromstring"), 503);
        $image = @imagecreatefromstring($file->getContent());
        abort_unless($image !== false, 422);
        ob_start();
        imagepng($image);
        $bytes = ob_get_clean();
        imagedestroy($image);
        abort_unless(is_string($bytes) && strlen($bytes) <= 8 * 1024 * 1024, 422);
        $path = "community-media/" . $user->id . "/" . Str::uuid() . ".enc";
        $saved = Storage::disk("local")->put($path, Crypt::encryptString(base64_encode($bytes)));
        abort_unless($saved, 503);
        return $path;
    }
    public function read(CommunityPost $post): array
    {
        abort_unless($post->image_path && Storage::disk("local")->exists($post->image_path), 404);
        return [
            "mime_type" => "image/png",
            "base64" => Crypt::decryptString(Storage::disk("local")->get($post->image_path))
        ];
    }
    public function delete(?string $path): void
    {
        if ($path) {
            Storage::disk("local")->delete($path);
        }
    }
    public function deleteForUser(User $user): void
    {
        Storage::disk("local")->deleteDirectory("community-media/" . $user->id);
    }
}
