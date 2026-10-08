# Mulai dari sini — Hopely Care

Proyek ini mengikuti **master requirement → prototipe Stitch → revisi percakapan → proposal lama untuk latar belakang**.

Isi proyek sudah mencakup kode Flutter, Laravel, FastAPI, migration, consent/caregiver permissions, engine tren, provider AI, RAG, ringkasan dokter, konfigurasi Docker, data demo, dan tes. Arsitekturnya tetap **Flutter → Laravel → FastAPI**, dengan MySQL di Laravel dan Qdrant untuk pengetahuan terkurasi.

**Status terverifikasi:** 37 tes FastAPI lulus dan lint Python lulus. Source PHP/Dart sudah diperiksa sintaksnya. Laravel, Flutter, Docker, AI live, FCM, dan ekspor PDF native **belum diuji end-to-end** di environment pembuatan.

## Urutan membaca

| Kebutuhan | File di dalam proyek |
|---|---|
| Cara memasang dan menjalankan | `README.md` |
| Keputusan arsitektur dan konflik dengan prototype | `docs/ARCHITECTURE.md` |
| ERD dalam Mermaid | `docs/DATABASE_ERD.md` |
| Alur aplikasi dalam Mermaid | `docs/APPLICATION_FLOW.md` |
| Diagram dan cara kerja AI | `docs/AI_ENGINE.md` |
| Kontrak Laravel dan FastAPI | `docs/API_CONTRACT.md`, `docs/AI_OPENAPI.json` |
| Privasi dan batas keselamatan | `docs/PRIVACY_AND_SAFETY.md` |
| Roadmap dan risiko | `docs/ROADMAP.md` |
| Hasil tes serta hal yang belum diverifikasi | `docs/VERIFICATION.md` |
| Skenario presentasi juri | `docs/DEMO.md` |

## Menjalankan setelah alat pengembangan tersedia

Ekstrak ZIP, buka folder `hopely-care` sebagai workspace, lalu ikuti README. Untuk backend lokal:

```sh
python scripts/configure.py
docker compose up --build -d
docker compose exec backend php artisan db:seed
```

Untuk mobile:

```sh
python scripts/bootstrap_mobile.py
cd mobile
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Perintah di atas adalah langkah berikutnya untuk dijalankan pada mesin dengan SDK yang sesuai, **bukan perintah yang sudah berhasil dieksekusi di environment ini**.

Akun demo memakai alamat `patient.demo@hopely.invalid` dan `caregiver.demo@hopely.invalid`. Password dibuat acak oleh `configure.py` dalam `.env` milikmu. Jangan unggah `.env` ke GitHub.

Mode awal adalah `MOCK_AI_MODE=true` dengan label demo terlihat. Untuk menilai kualitas AI nyata, konfigurasi provider dan lakukan evaluasi live terlebih dahulu. Community dan Meaningful Moments ditunda sesuai master requirement.
