# Support Circle

Support Circle adalah komunitas untuk berbagi pengalaman dan dukungan. Fitur ini mengikuti instruksi revisi 12 Oktober 2026 dan terintegrasi dengan Flutter, Laravel/Sanctum, MySQL, serta FastAPI yang sudah ada. Care Circle tetap merupakan hubungan pendamping pribadi melalui undangan.

## Menjalankan pembaruan pada Windows dan HP USB

Hentikan proses Flutter lama. Dari repository lokal:

```powershell
Set-Location "D:\LOMBA IEIC\hopely-care"
git fetch origin
git switch feature/support-circle
git pull --ff-only origin feature/support-circle
Set-Location .\backend
composer install
php artisan optimize:clear
php artisan migrate
php artisan db:seed --class=CommunitySeeder
php artisan serve --host=127.0.0.1 --port=8000
```

Gunakan `.env`, database, dan APP_KEY yang sudah berfungsi. Pembaruan menambah tabel; tidak memerlukan reset database atau pembuatan key baru. Bila Git melaporkan perubahan lokal, simpan perubahan itu sebelum berpindah branch.

Pada terminal PowerShell kedua:

```powershell
Set-Location "D:\LOMBA IEIC\hopely-care\mobile"
$env:PUB_CACHE = "D:\PubCache"
flutter pub get
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

PUB_CACHE pada drive D menghindari masalah jalur Kotlin yang pernah muncul ketika proyek dan cache berada di drive berbeda. Jika beberapa HP tersambung, pilih ID perangkat yang sama pada `adb -s <id> reverse ...` dan `flutter run -d <id> ...`. Mapping USB perlu diulang setelah sambungan berubah. Daftar/login memakai akun milik sendiri; `CommunitySeeder` hanya menambah lima komunitas dan tidak membuat akun demo.

PHP membutuhkan GD untuk unggahan foto komunitas. Periksa `php -m`; pada XAMPP aktifkan `extension=gd` di php.ini yang dipakai CLI, lalu mulai ulang Laravel. Docker/CI sudah memasang GD. Foto profil dan foto komunitas tetap memakai penyimpanan privat, tanpa `storage:link`.

Untuk Docker, `docker compose up --build -d --wait` menjalankan migration dan seed katalog secara idempoten. Secret dan volume lama dipertahankan. Jangan menjalankan pengujian smoke pada database pasien: smoke hanya untuk stack disposable dengan data sintetis.

## Alur pengguna dan layar

Lima tab utama tetap Beranda, Perjalanan, Hopely AI, Insight, dan Profil. Buka **Lihat Komunitas** pada Beranda atau **Support Circle • Komunitas** pada Profil.

| Layar | Route Flutter | Fungsi |
|---|---|---|
| Support Circle | `/community` | Pilihan komunitas, komunitas diikuti, cerita terbaru |
| Temukan Komunitas | `/community/discover` | Pencarian, kategori, urutan relevan/terbaru/aktif 7 hari |
| Ruang Komunitas | `/community/groups/:id` | Pedoman, anggota, gabung/keluar, feed |
| Cerita Komunitas / Ceritaku | `/community/feed`, `?mine=1` | Feed dengan pagination dan pengelolaan cerita sendiri |
| Bagikan / Edit Cerita | `/community/compose` | Teks, foto opsional, pilihan komunitas, persetujuan berbagi |
| Cerita & Dukungan | `/community/posts/:id` | Dukungan, komentar, report, block, hapus milik sendiri |
| Komunitasku | `/community/mine` | Keanggotaan dan keluar dari komunitas |
| Keamanan Komunitas | `/community/safety` | Pedoman, riwayat laporan, daftar blokir |
| Pengaturan Komunitas | `/community/preferences` | Nama publik, notifikasi, minat dan persetujuan pencocokan |
| Antrean Moderasi | `/community/moderation` | Peninjauan cerita, komentar, laporan; hanya moderator/admin |

Desain menggunakan kartu putih, latar `#F8FAFF`, aksen `#2563EB`/`#1E40AF`, dan bidang lembut `#DBEAFE`. Folder root `stitch v2` yang terverifikasi berisi 15 referensi layar lama, tanpa screenshot khusus komunitas. Layar baru menerapkan bahasa visual tersebut; tidak diklaim sebagai salinan screenshot komunitas yang belum tersedia.

## Moderasi saat AI belum aktif

`MOCK_AI_MODE=true` tidak memengaruhi login. Untuk komunitas, mode ini menahan pengajuan baru sampai moderator meninjaunya. Tidak ada persetujuan publikasi palsu dari fixture AI. Gangguan AI juga menyimpan cerita sebagai pending. Foto selalu memerlukan peninjauan manusia karena layanan moderasi MVP hanya memeriksa teks.

Operator perlu menunjuk akun moderator yang sudah terdaftar, per komunitas:

```powershell
php artisan community:moderator "email-akun-moderator" dukungan-emosional
```

Jalankan perintah tersebut di folder `backend` dengan email akun sebenarnya. Slug katalog lainnya: `pejuang-kanker-payudara`, `menjalani-kemoterapi`, `baru-didiagnosis`, `survivor-pemulihan`. Untuk Docker, awali dengan `docker compose exec backend`.

Moderator masuk ke akun itu, membuka Support Circle → Keamanan → Antrean moderasi, membaca isi/foto, lalu menerbitkan atau menghapus publikasi dengan alasan. Moderator hanya berwenang pada komunitas penugasannya; ADMIN memiliki ruang lingkup global. Pengguna tidak dapat memberi dirinya role lewat API. Cerita moderator sendiri perlu ditinjau moderator lain. Revisi konten diperiksa saat keputusan dibuat agar review lama tidak berlaku untuk isi yang sudah diubah.

| Hasil pemeriksaan | Penyimpanan Laravel | Perilaku |
|---|---|---|
| Live model: safe, keyakinan ≥0.8, tanpa kategori risiko, teks saja | approved | Terbit |
| Ketidakpastian, tripwire, mock, provider gagal, atau ada foto | pending | Hanya penulis dan moderator yang berwenang dapat membacanya |
| Hasil unsafe | flagged | Ditahan; dapat ditinjau manusia |
| Keputusan manusia menghapus publikasi | removed | Tidak terlihat oleh anggota lain; penulis dapat melihat status dan menghapusnya |

Tripwire adalah pemeriksaan konservatif untuk mengarahkan ke peninjauan, bukan classifier klinis. Live inference menggunakan adapter LLM terstruktur yang sudah ada. Tidak ada penghapusan permanen otomatis berdasarkan keputusan model. Uji live provider dan evaluasi kualitas moderasi bahasa Indonesia tetap diperlukan sebelum penggunaan publik.

## Privasi, data, dan notifikasi

- Nama komunitas dipilih saat bergabung. Email, nama akun pribadi, foto profil privat, profil medis, jurnal, chat, gejala, tren, dan laporan dokter tidak ikut dibagikan.
- Membaca komunitas aktif memerlukan login. Bergabung diperlukan untuk membuat cerita, komentar, atau reaction. Keanggotaan banned tidak bisa dipulihkan sendiri lewat keluar/gabung.
- Pencocokan opsional hanya menerima minat yang diisi di Pengaturan Komunitas. Tidak membaca profil pasien. Minat dienkripsi dan dihapus saat izin pencocokan dimatikan. Pencocokan menggunakan metadata, bukan embedding/ML; tidak otomatis memasukkan pengguna ke grup.
- Isi cerita, komentar, alasan report, dan metadata moderasi disimpan terenkripsi. Foto JPG/PNG/WebP ≤2 MB dan ≤4096×4096 dire-encode menjadi PNG untuk membuang metadata EXIF/lokasi, dienkripsi di disk privat, dan hanya dibaca lewat API yang memeriksa izin. Foto profil privat tidak menjadi avatar publik secara otomatis.
- Blokir berlaku dua arah pada cerita, komentar, reaction/count, dan pemberitahuan interaksi berikutnya. Moderator berwenang tetap dapat memeriksa konten yang dilaporkan.
- Hapus cerita/komentar milik sendiri menghilangkannya dari feed melalui soft delete. Foto cerita dihapus saat penulis menghapus cerita; semua data dan file milik akun dibersihkan saat akun dihapus. Belum ada jadwal retensi otomatis untuk baris soft-deleted dan publikasi removed; kebijakan retensi perlu ditentukan operator.
- Notifikasi `community_comment`, `community_reaction`, `community_report_update`, dan `community_moderation` memakai isi generik. Dedupe membatasi satu jenis pembaruan per subjek/penerima per hari. Preferensi notifikasi komunitas dapat dimatikan. Push memerlukan konfigurasi FCM; notifikasi dalam aplikasi tetap berfungsi tanpa FCM.

Migration `2026_10_12_000001_create_support_circle_tables.php` menambah `communities`, `community_members`, `community_posts`, `community_comments`, `community_reactions`, `community_reports`, `blocked_users`, dan `community_preferences`. UUID primary key mengikuti schema proyek. Tidak ada perubahan kolom tabel lama. Membership dan reaction unik per pasangan; FK, index feed/queue, soft delete dan revision melindungi integritas data.

## Seed dan batas MVP

`CommunitySeeder` idempoten dan hanya membuat katalog. `php artisan db:seed --class=CommunityDemoSeeder` adalah pilihan terpisah untuk lingkungan pengembangan: cerita dan anggota sintetis ditandai jelas, tanpa kata sandi demo yang dipakai login pengguna. Demo seed ditolak di production.

Belum ada video, saved posts, DM antar anggota, pembuatan komunitas oleh pengguna, verifikasi diagnosis, dashboard pengelolaan katalog/ban, atau undangan ke komunitas melalui email. Penugasan moderator memakai CLI. Pengguna memilih relevansi sendiri; diagnosis tidak disimpulkan dari data kesehatan. `image_url` disediakan pada schema katalog tetapi tidak menjadi sumber gambar eksternal otomatis pada Flutter.

Pemeriksaan komponen mencakup membership/ownership, publikasi saat provider gagal, review moderator dan revisi, report, block, notification opt-out, gambar privat dan penghapusan akun. Smoke Docker menguji API nyata Laravel → MySQL → FastAPI dengan konten sintetis; Flutter widget tests memakai fixture terbatas pada folder test. Hasil final dan batas uji perangkat/live AI dicatat di [VERIFICATION.md](VERIFICATION.md).
