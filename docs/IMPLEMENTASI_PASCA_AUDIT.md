# Implementasi pasca-audit fungsional

Tanggal: 29 Oktober 2026. Dokumen audit awal tetap merupakan snapshot sebelum perubahan; status berikut tidak berarti seluruh integrasi produksi telah diverifikasi.

## Perubahan yang sudah masuk kode

- Bantuan Cepat membedakan permintaan tercatat, jumlah target, penerimaan oleh provider push, dan acknowledgment caregiver. Tidak lagi mengklaim perangkat/orang menerima hanya karena baris DB dibuat. Arahan darurat ditampilkan.
- NotificationService menyimpan status/attempt push. Scheduler `hopely:retry-notifications` mencoba ulang notifikasi tertentu, maksimum lima percobaan pengiriman dalam jendela satu hari. Link/izin caregiver dan status alert diperiksa ulang untuk retry Bantuan Cepat. Penerimaan provider bukan bukti delivery perangkat. Retry notifikasi komunitas belum diaktifkan karena membutuhkan pemeriksaan ulang izin domain tersendiri.
- AI Reflection menghasilkan narasi reflektif dan pertanyaan opsional, diperiksa safety, disimpan encrypted, dan ditampilkan pada jurnal. Krisis diarahkan ke bantuan manusia.
- Doctor Summary tetap mengembalikan agregat tercatat ketika narasi AI gagal, dengan metadata fallback dan pemberitahuan pada layar/PDF; tidak membuat narasi AI palsu.
- Role SUPER_ADMIN, CONTENT_ADMIN, COMMUNITY_MODERATOR ditambahkan lewat migration. Moderator global dapat mengakses antrean/review; role konten tetap tidak mendapat akses moderasi.
- Hasil moderasi model/rules berisiko menjadi flagged untuk review manusia, bukan keputusan penghapusan final otomatis.
- Workflow dokumen kesehatan di MySQL: draf, revision check, review oleh akun berbeda, publish artikel, index RAG, unpublish. Artikel published dapat dibaca tanpa Qdrant. API legacy ingest kini membuat draf agar tidak melewati review.
- FastAPI mempunyai endpoint penghapusan sumber `/v1/knowledge/remove`; withdrawal sumber diuji pada Qdrant in-memory.
- Nama akun dapat diperbarui pasien/caregiver melalui PUT `/api/me` dan tombol profil. Nama PatientProfile/User diselaraskan.
- Pengingat aktivitas rekomendasi dapat dijadwalkan dari detail aktivitas; scheduler menghormati consent, kepemilikan, completed status dan deduplikasi.
- Empat lint Flutter yang ditemukan saat audit diperbaiki.

## Pengujian terakhir

| Pemeriksaan | Hasil |
|---|---|
| Laravel PHPUnit, SQLite in-memory | 51 tests, 329 assertions, lulus |
| FastAPI pytest | 56 passed |
| Flutter test --no-pub | 54 lulus |
| Flutter analyze --no-pub | No issues found, exit 0 |
| Probe provider live rekomendasi dan summary | Keduanya berhasil pada pengujian ulang melalui AIEngine; metadata live, tanpa fallback |

Keberhasilan probe ulang tidak menjelaskan akar kegagalan 503 audit awal dan tidak membuktikan kestabilan provider. Tes baru menguji narasi reflection, krisis, fallback summary, penarikan sumber RAG, workflow review/publish, stale revision, gagal withdrawal, role moderator, edit nama owner-only, serta reminder aktivitas.

## Penerapan

Migration baru belum diterapkan ke database operasional. Sebelum deploy, lakukan backup sesuai prosedur pengelola dan uji migration pada salinan/staging MySQL. Deploy backend dan FastAPI yang kompatibel bersama, jalankan migration, lalu rebuild Flutter. Scheduler diperlukan untuk reminder dan retry.

Migration ekspansi role sengaja tidak otomatis mempersempit enum saat rollback agar akun staff tidak terdemosi/terhapus diam-diam. Rollback role memerlukan penanganan akun secara eksplisit.

## Pekerjaan yang masih terbuka

1. RAG live: dependency sentence-transformers, bobot embedding, Qdrant yang berjalan dan dokumen kesehatan yang benar-benar ditinjau. Tidak ada dokumen medis palsu atau klaim review klinis yang dibuat.
2. Evaluasi AI berpasangan dengan/tanpa konteks, ketepatan retrieval, dan keselamatan Bahasa Indonesia belum selesai.
3. End-to-end Flutter–Laravel–MySQL–FastAPI, PDF/plugin perangkat, pengiriman email nyata dan FCM perangkat belum diverifikasi.
4. Workflow dokumen menggunakan transaksi DB yang memanggil layanan indeks saat index/unpublish. Transaksi lintas Qdrant/DB tidak atomik; masih perlu outbox/reconciliation dan pengujian kegagalan pasca-remote-success. Legacy artikel file belum dimigrasikan otomatis ke workflow baru.
5. Rekomendasi kini hanya memakai aktivitas active dan medically_reviewed, maksimum 30 sesuai kontrak FastAPI. Kurasi masih menggunakan flag administratif; belum ada workflow independent review aktivitas seperti dokumen.
6. Retry notification tidak menyediakan jaminan exactly-once atau delivery receipt perangkat. Status sending yang tertinggal dapat dicoba ulang setelah lima menit; retry komunitas belum lengkap.
7. Revisi consent dan arsip DoctorVisitReport masih perlu keputusan retensi yang eksplisit serta pengujian race MySQL.

Tidak melakukan commit/push atau migrasi database operasional selama pengerjaan ini.
