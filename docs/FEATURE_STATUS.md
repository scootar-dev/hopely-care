# Status komunitas, tools, kerabat, dan foto profil

## Komunitas dan Care Circle

Support Circle antar pasien belum diimplementasikan. Master requirement menempatkannya pada fase lanjutan setelah inti aplikasi stabil. Bila dikembangkan, pengguna memilih bergabung ke kelompok kecil sesuai kebutuhan dukungan, fase perawatan, preferensi komunikasi, dan konteks kanker yang bersedia dibagikan. Tidak ada pencocokan otomatis atau pembukaan data kesehatan sekarang. Report, block, dan moderasi manusia tetap diperlukan.

Care Circle yang sudah ada menghubungkan pasien dengan akun **Kerabat** melalui undangan pribadi. Ini bukan komunitas antar pasien.

## Pengelolaan Tools Kesehatan

| Isi | Pengelola / sumber | Implementasi saat ini |
|---|---|---|
| Jadwal, check-in, gejala | Pasien mengisi dan memperbarui catatan sendiri | Flutter → API → MySQL |
| Aktivitas relaksasi/dukungan | Admin/pengelola konten mengkurasi; status tinjauan medis harus sesuai fakta | API ADMIN untuk membuat/memperbarui aktivitas; belum ada dashboard admin |
| Informasi tepercaya | Admin mengunggah dokumen dengan sumber dan metadata review | Ingestion API + Qdrant; jawaban memerlukan AI dan korpus terkurasi |
| Ringkasan dokter | Dibentuk dari catatan pasien untuk ditinjau pasien | Pemrosesan melalui backend dan AI Engine |

Pustaka aktivitas pada instalasi baru dapat kosong. Akun sendiri tidak memerlukan seed demo. Tambahkan konten melalui API admin (`POST /admin/activities`, `PUT /admin/activities/{id}`) dan dokumen melalui `POST /admin/knowledge/ingest`. Jangan menandai konten sebagai ditinjau medis tanpa peninjauan sebenarnya. AI hanya memilih aktivitas dalam pustaka; AI tidak menerbitkan aktivitas medis baru sendiri.

## Undang kerabat

Beranda **Undang kerabat tepercaya** dan Profil **Undang & kelola kerabat** sama-sama membuka `/care-circle`.

1. Pasien memasukkan email pendamping dan hubungan/panggilan.
2. Email harus milik akun Kerabat, atau belum terdaftar. Akun Pasien tidak bisa menerima undangan caregiver.
3. Pasien membuat kode, menyalin, lalu mengirimkannya secara pribadi. Aplikasi belum mengirim email undangan otomatis.
4. Pendamping mendaftar/login sebagai Kerabat dengan email yang diundang, lalu memasukkan kode.
5. Kode berlaku 48 jam dan sekali pakai. Semua izin mulai nonaktif. Pasien mengatur izin per kerabat dan persetujuan berbagi di Privasi.

Form kini memeriksa email sendiri/isian kosong dan menjelaskan kegagalan undangan secara khusus. Penyebab laporan kegagalan khusus beranda di perangkat pengguna belum dapat ditentukan tanpa pesan error/perilaku tombol pada build yang dipakai.

## Foto profil

Pasien dan Kerabat dapat memilih foto dari galeri, melihat preview, menyimpan penggantinya, atau menghapus foto di Profil. Header aplikasi ikut memperbarui foto. Pilihan yang dibatalkan tidak diunggah. Setelah login ulang, foto dimuat dari backend.

Format JPG/PNG/WebP, maksimum 2 MB dan 4096×4096 piksel; pemilih foto mobile meminta pengecilan hingga 1024×1024. Android minimum SDK 24 mengikuti `image_picker` 1.2.4. iOS memiliki keterangan izin galeri; tidak meminta akses kamera.

API pemilik akun: GET/POST/DELETE `/api/me/avatar`. POST memakai multipart field `photo`; GET mengembalikan `data: null` atau `{mime_type, base64}`. Hanya token pemilik yang dapat membaca/mengubahnya. Foto disimpan terenkripsi menggunakan APP_KEY di disk private Laravel, tanpa URL publik, dan dihapus bersama akun. Tidak perlu migrasi tabel baru atau `storage:link`. Storage backend harus persisten; Compose sudah memakai volume backend-storage.

## Provider AI dan biaya

Implementasi live saat ini hanya memiliki adapter OpenAI; `MOCK_AI_MODE` tidak memengaruhi login atau foto. Key provider lain tidak dapat langsung dimasukkan sebagai pengganti key OpenAI. Gemini/Groq/local model memerlukan adapter dan pengujian structured output serta safety yang sama.

[Billing API OpenAI](https://help.openai.com/en/articles/9039756-managing-billing-for-chatgpt-and-the-api-platform) terpisah dari langganan ChatGPT. [Gemini menyediakan kuota gratis untuk model tertentu](https://ai.google.dev/gemini-api/docs/billing), tetapi [ketentuan layanan gratisnya](https://ai.google.dev/gemini-api/terms) tidak mengizinkan pengiriman informasi pribadi/sensitif. Jika mengevaluasi free tier, gunakan data sintetis; data pasien nyata memerlukan penilaian pengaturan privasi provider dan consent yang sesuai.
