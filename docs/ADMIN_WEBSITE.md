# Website admin Hopely Care

Dashboard admin dilayani Laravel pada `/admin`, terpisah dari aplikasi mobile.

## Menjalankan lokal

Jalankan MySQL dan layanan AI sesuai konfigurasi backend, lalu dari folder `backend`:

```sh
php artisan migrate
php artisan db:seed --class=AdminSeeder
php artisan serve --host=127.0.0.1 --port=8000
```

Buka http://127.0.0.1:8000/admin.

Akun default:
- Email: `admin@hopely.care`
- Password: `HopelyAdmin123!`

Seeder tidak menimpa password atau role akun yang sudah ada. Akun dibuat di database ketika perintah seeder berhasil dijalankan. Login mobile menolak akun admin; sesi admin mobile lama dibersihkan saat refresh.

## Fitur

- Aktivitas: pencarian, pagination, tambah/edit, status aktif dan peninjauan medis.
- Pengetahuan: input dokumen, metadata sumber, tanggal, versi, reviewer; ingest AI dan publikasi artikel mobile.
- Komunitas, laporan, pengguna, bantuan cepat, audit: pencarian, pagination dan detail data sesuai endpoint workspace.
- Moderasi untuk role ADMIN: antrean postingan/komentar/laporan, lihat gambar, approve/remove/dismiss dengan catatan dan pemeriksaan revisi.
- Login admin dan logout dengan pencabutan token. Token hanya disimpan pada sessionStorage tab browser.

Role CONTENT_ADMIN mendapat aktivitas dan pengetahuan. SUPER_ADMIN mendapat seluruh modul workspace dan pengelolaan konten; moderasi tetap mengikuti otorisasi backend yang saat ini hanya memberi akses global kepada ADMIN. COMMUNITY_MODERATOR mendapat modul komunitas dan laporan sesuai endpoint workspace.

Modul daftar pengguna/komunitas/bantuan cepat/audit merupakan monitor data; backend tidak menyediakan mutasi admin untuk modul tersebut. Dokumen yang telah berada di indeks AI sebelum fitur publikasi artikel tidak otomatis menjadi artikel.
