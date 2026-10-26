<?php
namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        $email = 'admin@hopely.care';
        if (User::where('email', $email)->exists()) {
            $this->command?->info('Akun sudah ada; password dan peran dipertahankan.');
            return;
        }
        $user = new User();
        $user->forceFill(['name' => 'Hopely Administrator', 'email' => $email,
            'password' => 'HopelyAdmin123!', 'role' => 'ADMIN'])->save();
        $this->command?->info('Admin dibuat: admin@hopely.care');
    }
}
