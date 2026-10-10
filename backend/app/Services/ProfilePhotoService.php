<?php
namespace App\Services;

use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\{Crypt, Storage};

class ProfilePhotoService
{
    private function path(User $user): string
    {
        return "profile-photos/{$user->id}.enc";
    }

    public function read(User $user): ?array
    {
        $disk = Storage::disk("local");
        if (!$disk->exists($this->path($user))) {
            return null;
        }
        return json_decode(
            Crypt::decryptString($disk->get($this->path($user))),
            true,
            flags: JSON_THROW_ON_ERROR,
        );
    }

    public function replace(User $user, UploadedFile $photo): array
    {
        $data = [
            "mime_type" => $photo->getMimeType(),
            "base64" => base64_encode($photo->get()),
        ];
        // One encrypted file per account, outside the public web directory.
        // Never use an uploaded filename or a client-supplied user ID as a path.
        Storage::disk("local")->put(
            $this->path($user),
            Crypt::encryptString(json_encode($data, JSON_THROW_ON_ERROR)),
        );
        return $data;
    }

    public function delete(User $user): void
    {
        Storage::disk("local")->delete($this->path($user));
    }
}
