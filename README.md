# Hopely Care

MVP pendamping wellbeing pasien kanker, dilanjutkan dari repository utama dan diselaraskan dengan master requirement serta 15 layar Stitch V2 di `stitch v2/`. Proposal lama hanya digunakan untuk latar belakang.

**Status:** implementasi Stitch V2 dan perbaikan regresi tersedia. Tes FastAPI, Laravel (SQLite dan MySQL), serta analisis dan tes Flutter telah dijalankan melalui GitHub Actions. Hasil build dan batas verifikasi dicatat di [VERIFICATION.md](docs/VERIFICATION.md); pemetaan desain dan keputusan implementasi ada di [STITCH_V2_AUDIT.md](docs/STITCH_V2_AUDIT.md).

Status komunitas, pengelola Tools Kesehatan, undangan kerabat, foto profil, dan provider AI dijelaskan di [FEATURE_STATUS.md](docs/FEATURE_STATUS.md). Foto profil dapat dipilih/diganti/dihapus dari Profil; gunakan `flutter pub get` dan restart penuh karena ada plugin galeri baru. Android minimum SDK 24. Backend perlu diperbarui bersamaan; fitur foto tidak menambah migrasi database.

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
- PHP 8.4 target Docker/CI; Laravel 12.69.3 dan Sanctum 4.3.3 sesuai `backend/composer.lock` pada repository utama. Versi backend pengguna dipertahankan.
- Flutter stable, Dart ≥3.10; minimum Flutter pada lockfile ≥3.44.0. Dependency penting: Riverpod `^3.4.3`, GoRouter `^18.0.2`, secure storage `^11.2.0`; versi terkunci ada di `mobile/pubspec.lock`.
- Python 3.12; FastAPI 0.142.2, Pydantic 2.13.5 yang diuji, HTTPX 0.28.1, qdrant-client 1.19.1, OpenAI SDK 3.26.0. Lihat pyproject dan `ai-service/requirements-tested.txt`.
- MySQL 8.4 LTS, Qdrant 1.19.2, Docker Engine/Desktop + Compose v2.
- Android SDK/emulator untuk mobile; Xcode/macOS untuk iOS.

`backend/composer.lock`, `mobile/pubspec.lock`, dan native runners Android/iOS/web sudah tersedia dari repository utama dan dipertahankan. Jalankan instalasi dari lockfile; evaluasi upgrade dependency secara terpisah.

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

Bootstrap membuat runner Android/iOS hanya bila direktori platform belum tersedia, mengambil dependency, dan mengizinkan HTTP hanya pada manifest Android debug. CI langsung menjalankan `flutter pub get` pada runner yang sudah ada. APK release mensyaratkan `API_BASE_URL=https://...`. Pada iOS gunakan endpoint HTTPS pengembangan atau konfigurasikan pengecualian ATS khusus debug secara sengaja.

Alamat default tanpa `--dart-define` mengikuti lingkungan pengembangan: Android memakai `http://10.0.2.2:8000/api` untuk Android Emulator; desktop/web memakai `http://127.0.0.1:8000/api`. `API_BASE_URL` eksplisit selalu diprioritaskan. HP fisik memerlukan pengaturan endpoint sendiri; alamat emulator tidak berlaku untuk HP fisik.

## Jika login email gagal

`flutter run` hanya menyalakan aplikasi Flutter. Laravel dan database harus berjalan terpisah. Login menerima email dan kata sandi **akun Hopely Care** yang sudah didaftarkan lewat **Buat akun baru**. Ini bukan login Google/Gmail, OTP email, atau kata sandi kotak masuk email. Registrasi memerlukan kata sandi minimal 12 karakter. Akun demo baru tersedia setelah seeder dijalankan; kata sandinya adalah `DEMO_PASSWORD` pada konfigurasi lokal saat pertama kali di-seed.

1. Periksa `http://localhost:8000/up` di browser komputer. Jika belum dapat dibuka, periksa proses Laravel atau `docker compose ps -a`. Health ini menunjukkan aplikasi Laravel hidup; keberhasilan login juga memerlukan koneksi database dan migration.
2. Gunakan alamat sesuai perangkat:

   | Perangkat | Perintah dari folder `mobile` |
   |---|---|
   | Android Emulator | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api` |
   | Chrome pada komputer backend | `flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api` |
   | HP Android tersambung USB | Jalankan `adb reverse tcp:8000 tcp:8000`, lalu `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api` |

   Untuk HP tanpa USB, gunakan endpoint HTTPS pengembangan yang dapat dicapai HP. Mapping Docker bawaan hanya membuka port pada loopback komputer; mengganti URL Flutter ke IP Wi-Fi saja tidak membuka port tersebut. Bila beberapa perangkat terhubung, pilih perangkat yang sama pada `adb -s <id> reverse ...` dan `flutter run -d <id> ...`.
3. Hentikan Flutter dan jalankan ulang setelah mengubah `--dart-define`; alamat API ditentukan saat build. Jangan menghapus database untuk mencoba memperbaiki login.
4. Pesan email/kata sandi tidak sesuai menunjukkan respons 401. Pesan validasi menunjukkan 422. Gangguan layanan akun menunjukkan respons 5xx. Jika belum terhubung, periksa proses backend, alamat API, dan jaringan perangkat. Kirim pesan error, jenis perangkat, dan perintah menjalankan aplikasi untuk diagnosis; jangan kirim kata sandi, token, API key, atau isi `.env`.

AI tidak diperlukan oleh endpoint login. Pada Docker Compose, startup backend memang menunggu service AI sehat; konfigurasi AI yang gagal saat startup dapat membuat backend belum mulai. Periksa status semua container jika health Laravel belum tersedia.

Aplikasi memakai Bahasa Indonesia, Material 3, tema biru/lavender Stitch V2, kartu membulat, dan navigasi Beranda / Perjalanan / Hopely AI / Insight / Profil. Onboarding, Tools Kesehatan, penerimaan undangan, dan detail pengingat dukungan telah ditambahkan. Ilustrasi ikon Flutter menggantikan aset gambar terpisah yang tidak tersedia. Screenshot bukan data pasien dan teks medis contoh tidak dipakai sebagai fakta.

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

CI menjalankan Python, Laravel pada SQLite dan MySQL 8.4, serta Flutter analyze/test/debug APK. Artifact `stitch-v2-screens` berisi render widget dengan data sintetis; `hopely-care-debug-apk` berisi APK untuk endpoint emulator `http://10.0.2.2:8000/api`. Uji alur lintas layanan dan perangkat tetap terpisah. Skenario juri: `docs/DEMO.md`.

Job `stack-smoke` menyalakan Docker Compose dengan secret baru dan database kosong, lalu menjalankan `python scripts/smoke_stack.py`. Uji ini menggunakan HTTP nyata untuk preflight browser, daftar, login, token, profil, izin, serta chat Laravel → FastAPI **mode mock** dan penyimpanannya di MySQL. Akun sintetis dihapus setelah uji. Hasilnya harus dilihat pada run CI untuk commit yang dipakai; uji ini tidak membuktikan provider LLM live atau jaringan perangkat pengguna. Jangan menjalankan smoke test pada deployment produksi.

## Batas implementasi yang masih harus diverifikasi
- Rangkaian Flutter pada perangkat pengguna → Laravel → FastAPI belum diuji end-to-end. CI kini memiliki uji HTTP stack Docker terpisah; periksa status job `stack-smoke` sebelum menganggap alur layanan tersebut lulus.
- Tidak ada API key live, dokumen medis yang benar-benar disetujui, atau konfigurasi Firebase milik pengguna.
- Belum ada uji klinis, pengukuran akurasi emosi, evaluasi krisis/parafrasa Bahasa Indonesia, ataupun validasi manfaat kesehatan.
- Form edit/delete tersedia untuk inti pencatatan melalui API; UI memperlihatkan jalur utama, bukan semua operasi administratif. Jurnal memiliki navigasi halaman. Daftar lain masih mengambil halaman pertama (30 item), dan chat membuka sesi terbaru; navigasi riwayat panjang dapat dikembangkan berikutnya.
- Notifikasi push belum memakai antrean retry persisten; in-app notification tetap disimpan. Job/queue dapat ditambahkan saat kebutuhan delivery jelas.
- PDF tidak menyertakan otomatis isi jurnal/chat, diagnosis, dosis, atau informasi dokter yang tidak tercatat.
- Community dan Meaningful Moments ditunda sesuai prioritas master.

## Sumber dokumentasi teknis
Referensi: [Laravel 12](https://laravel.com/docs/12.x), [Flutter SDK](https://docs.flutter.dev/install/archive), [Riverpod](https://pub.dev/packages/flutter_riverpod), [GoRouter](https://pub.dev/packages/go_router), [Secure Storage](https://pub.dev/packages/flutter_secure_storage), [FCM setup](https://firebase.google.com/docs/flutter/setup), [Qdrant](https://github.com/qdrant/qdrant), [Structured outputs](https://developers.openai.com/api/docs/guides/structured-outputs), [Embedding model](https://huggingface.co/sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2). Untuk versi yang digunakan aplikasi, ikuti manifest dan lockfile repository.
