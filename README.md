# Hopely Care

Implementasi awal MVP pendamping wellbeing pasien kanker, mengikuti master requirement dan lima screenshot Stitch. Proposal lama tidak digunakan untuk menentukan fitur atau teknologi.

**Status:** kode aplikasi, layanan AI, konfigurasi, dan tes tersedia. Tes Python dijalankan di workspace ini. Build Flutter, eksekusi Laravel/MySQL, Docker, FCM, serta AI live belum dapat diverifikasi di sini. Lihat `docs/VERIFICATION.md`; jangan menganggap seluruh definition of done sudah terpenuhi.

## Arsitektur
Flutter → Laravel/Sanctum → MySQL dan FastAPI internal. FastAPI → provider LLM dan Qdrant untuk dokumen terkurasi. Flutter tidak memegang internal service key atau API key LLM. FCM dipakai hanya untuk notifikasi perangkat yang diaktifkan pengguna.

| Lokasi | Isi |
|---|---|
| `mobile/lib/core` | API, autentikasi, tema, router, komponen, notifikasi |
| `mobile/lib/features` | Layar pasien dan caregiver sesuai alur MVP |
| `backend/app` | Controller, FormRequest, Resource, policy, middleware, business services |
| `backend/database` | Migration domain dan seeder sintetis |
| `ai-service/app` | Schema, provider, safety, emosi, tren, RAG, orchestration |
| `infrastructure/docker` | Image dan startup lokal |
| `knowledge-base` | Petunjuk dokumen terkurasi; tidak memuat data pasien |
| `docs` | Arsitektur, ERD, flow, kontrak, privasi, roadmap, verifikasi |

## Versi dan kebutuhan
- PHP 8.4 target Docker; Laravel `^13.0`, Sanctum `^4.0`. Laravel 13 membutuhkan PHP minimal 8.3.
- Flutter stable (dokumentasi resmi saat pemeriksaan menampilkan 3.47), Dart ≥3.10. Dependency penting: Riverpod `^3.4.3`, GoRouter `^18.0.2`, secure storage `^11.2.0`; versi final harus dikunci oleh `flutter pub get`.
- Python 3.12; FastAPI 0.142.2, Pydantic 2.13.5 yang diuji, HTTPX 0.28.1, qdrant-client 1.19.1, OpenAI SDK 3.26.0. Lihat pyproject dan `ai-service/requirements-tested.txt`.
- MySQL 8.4 LTS, Qdrant 1.19.2, Docker Engine/Desktop + Compose v2.
- Android SDK/emulator untuk mobile; Xcode/macOS untuk iOS.

Composer dan Flutter SDK belum tersedia pada environment pembuatan, sehingga `composer.lock` dan `pubspec.lock` belum dihasilkan. Setelah dependency berhasil di-resolve dan dites, commit keduanya. Jangan menganggap rentang dependency sebagai reproducible lockfile.

## Mulai backend dengan Docker
Dari root proyek:

```sh
python scripts/configure.py
docker compose up --build -d
docker compose exec backend php artisan db:seed
```

`configure.py` membuat `.env` dengan secret acak dan tidak menimpa konfigurasi lama. Secret tidak dicetak dan tidak disertakan dalam paket. Baca `DEMO_PASSWORD` dari `.env` lokal untuk login demo, jangan membagikan atau commit file itu.

API Laravel: `http://localhost:8000/api`. Health Laravel: `http://localhost:8000/up`. MySQL, Qdrant, dan FastAPI tidak dipublikasikan ke host. API hanya bind ke loopback untuk pengembangan. Untuk emulator Android gunakan `10.0.2.2:8000`. Untuk perangkat nyata gunakan development tunnel/ingress yang kamu kendalikan, dan HTTPS pada release.

Data demo:
- `patient.demo@hopely.invalid` — Sarah (Demo Sintetik).
- `caregiver.demo@hopely.invalid` — Dimas (Demo Sintetik).
- Password berasal dari `DEMO_PASSWORD` milikmu.
- Seeder tidak berjalan di production, tidak menghapus data lama, dan tidak dijalankan otomatis saat container mulai.

## Menjalankan Flutter

```sh
python scripts/bootstrap_mobile.py
cd mobile
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Bootstrap membuat runner Android/iOS menggunakan SDK lokal, mempertahankan source aplikasi, mengambil dependency, dan mengizinkan HTTP hanya pada manifest Android debug. APK release mensyaratkan `API_BASE_URL=https://...`. Pada iOS gunakan endpoint HTTPS pengembangan atau konfigurasikan pengecualian ATS khusus debug secara sengaja. Commit runner dan lockfile hasil bootstrap setelah build berhasil.

Aplikasi memakai Bahasa Indonesia, Material 3, tema hijau/mint/peach, kartu membulat, dan navigasi bawah dari Stitch. Logo sederhana dan inisial menggantikan aset gambar yang tidak tersedia. Screenshot bukan data pasien dan teks medis contoh tidak dipakai sebagai fakta.

## Laravel tanpa Docker
Install PHP 8.3+, Composer, extension PDO MySQL/SQLite, mbstring, XML, tokenizer, ctype, fileinfo, zip. Sediakan MySQL sendiri. Salin variabel aplikasi/database/internal-service yang diperlukan ke `backend/.env`; buat APP_KEY lokal menggunakan Artisan.

```sh
cd backend
composer install
php artisan key:generate
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000
vendor/bin/phpunit
```

Jalankan `php artisan schedule:work` pada proses lain untuk reminder. Endpoint AI mengharapkan layanan internal berjalan dan key cocok. Production memakai web server/worker yang sesuai, bukan `artisan serve`.

## FastAPI tanpa Docker

```sh
cd ai-service
python -m venv .venv
# Aktifkan venv sesuai OS.
python -m pip install -e '.[dev]'
# Set INTERNAL_SERVICE_KEY minimal 32 karakter dan MOCK_AI_MODE=true di environment.
python -m uvicorn app.main:app --host 127.0.0.1 --port 8001 --no-access-log
python -m pytest -q
```

`GET /health` tidak memerlukan key. Semua endpoint lain memerlukan `X-Internal-Service-Key`. OpenAPI disediakan sebagai file `docs/AI_OPENAPI.json`; dokumentasi interaktif tidak dipublikasikan pada service.

## Mengaktifkan AI nyata
Set di `.env` lokal: `MOCK_AI_MODE=false`, `LLM_PROVIDER=openai`, `LLM_API_KEY=<secret milikmu>`, `LLM_MODEL=<model yang tersedia pada akunmu dan mendukung structured output>`. Restart container. Tidak ada model atau biaya API yang diasumsikan tersedia. Aplikasi memanggil antarmuka `LLMProvider`, bukan mengikat business layer ke vendor.

Untuk embedding lokal / transformer emosi, set `WITH_LOCAL_MODELS=true` lalu rebuild AI image. Image memasang PyTorch CPU dan extra ML. Tanpa pilihan ini, mode mock dapat berjalan tanpa mengunduh bobot model. `EMOTION_MODEL_NAME` boleh kosong; live emotion analysis memakai structured LLM classification dan mencatat fallback. Mengaktifkan transformer memerlukan model zero-shot multilingual yang sesuai serta evaluasi Bahasa Indonesia. Bobot/model bukan bagian paket.

Tren statistik tetap nyata pada data yang diberikan: calendar-aware slope, rolling average, baseline comparison, coverage, outlier deskriptif, dan catatan H-2…H+2. AI semantik menjalankan emosi, dialog kontekstual, ranking aktivitas, coach, dan penyusunan pertanyaan ringkasan. Output mock diberi label. Tidak ada klaim validasi klinis.

## RAG dan konten
Qdrant menyimpan hanya chunk sumber terkurasi, bukan jurnal/chat. Koleksi awal kosong dengan sengaja. Ikuti `knowledge-base/README.md`, tambahkan metadata dan persetujuan reviewer yang sebenarnya. Query dengan bukti lemah akan abstain. Pergantian embedding model membutuhkan re-indexing.

Admin memakai API `/api/admin/*`; tidak ada pendaftaran admin publik. Buat akun admin melalui `php artisan hopely:create-admin` dengan ADMIN_EMAIL, ADMIN_NAME dan ADMIN_PASSWORD pada environment operator. Tidak ada kata sandi default. Panel admin visual belum dibuat.

## FCM
Notifikasi dalam aplikasi dapat digunakan tanpa Firebase. Untuk push nyata:
1. Konfigurasikan aplikasi Android/iOS pada Firebase melalui FlutterFire CLI; ikuti konfigurasi native dan APNs/iOS.
2. Mount kredensial service account ke backend dan scheduler secara read-only, set `FCM_PROJECT_ID` dan `GOOGLE_APPLICATION_CREDENTIALS` ke path container. Jangan commit kredensial.
3. Jalankan mobile dengan `--dart-define=FCM_ENABLED=true`, lalu aktifkan pengingat pada Profil.
4. Scheduler menjalankan deduplikasi pengingat check-in/treatment. Isi push selalu generik.

Delivery FCM dan token refresh perlu pengujian perangkat nyata. Tidak ada notifikasi dikirim saat proyek ini dibuat.

## Privasi
Izin dimulai nonaktif pada akun baru. Health consent mengaktifkan pencatatan; izin AI chat, analisis jurnal, sharing dan alert terpisah. Analisis jurnal/catatan memerlukan izin global dan per-entry. Caregiver memerlukan link diterima, consent berbagi aktif, dan flag sesuai jenis data. Jurnal dan chat tidak pernah tampil pada endpoint caregiver.

Withdrawal menaikkan revision, membuang wawasan turunan, dan memblokir penyimpanan hasil inference lama. Pemrosesan yang telah dikirim ke provider tidak dapat ditarik kembali. Free text sensitif dienkripsi oleh Laravel. Provider call memakai `store=false`, tetapi kebijakan retention provider tetap perlu ditinjau. Dokumen PDF berada pada perangkat dan ekspor dipicu pasien.

## Tes dan demo

```sh
docker compose exec backend vendor/bin/phpunit
docker compose exec ai-service python -m pytest -q
```

CI menyediakan job Python, Laravel SQLite, Flutter analyze/test/debug APK. Jalankan juga dengan MySQL/Docker dan perangkat sebelum menganggap MVP selesai. Skenario juri: `docs/DEMO.md`.

## Batas implementasi yang masih harus diverifikasi
- Belum ada bukti build/run Laravel + Flutter + Docker secara end-to-end pada workspace ini.
- Tidak ada API key live, dokumen medis yang benar-benar disetujui, atau konfigurasi Firebase milik pengguna.
- Belum ada uji klinis, pengukuran akurasi emosi, evaluasi krisis/parafrasa Bahasa Indonesia, ataupun validasi manfaat kesehatan.
- Form edit/delete tersedia untuk inti pencatatan melalui API; UI memperlihatkan jalur utama, bukan semua operasi administratif. Riwayat daftar menggunakan halaman pertama (30 item); load-more dan pemilih sesi chat perlu ditambahkan sebelum penggunaan panjang.
- Notifikasi push belum memakai antrean retry persisten; in-app notification tetap disimpan. Job/queue dapat ditambahkan saat kebutuhan delivery jelas.
- PDF tidak menyertakan otomatis isi jurnal/chat, diagnosis, dosis, atau informasi dokter yang tidak tercatat.
- Community dan Meaningful Moments ditunda sesuai prioritas master.

## Sumber dokumentasi teknis
Diperiksa 7 Oktober 2026: [Laravel 13](https://laravel.com/framework/docs/releases), [Flutter SDK](https://docs.flutter.dev/install/archive), [Riverpod](https://pub.dev/packages/flutter_riverpod), [GoRouter](https://pub.dev/packages/go_router), [Secure Storage](https://pub.dev/packages/flutter_secure_storage), [FCM setup](https://firebase.google.com/docs/flutter/setup), [Qdrant 1.19.2](https://github.com/qdrant/qdrant/releases/tag/v1.19.2), [Structured outputs](https://developers.openai.com/api/docs/guides/structured-outputs), [Embedding model](https://huggingface.co/sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2).
