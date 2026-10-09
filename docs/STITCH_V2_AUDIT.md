# Audit dan implementasi Stitch V2

Baseline: `scootar-dev/hopely-care`, branch `main`, commit `4c3a5d5fd6898bd4c93c34785e75a649ca7bd99c` (9 Oktober 2026). Repository diklon langsung; file Flutter, Laravel, dan FastAPI dibaca sebelum perubahan. Branch kerja: `codex/stitch-v2-completion`.

## Sumber dan kondisi awal

Urutan: master requirement → Stitch V2 → instruksi revisi → proposal lama hanya latar belakang. Lima gambar `docs/reference/` adalah versi lama. Semua 15 PNG di `stitch v2/` diperiksa secara visual. Master requirement di repo sama secara teks dengan paket awal, dengan normalisasi line ending.

Repo sudah memiliki native runners Android/iOS/web, lockfile Composer/pub, penyesuaian tema biru, dan perubahan backend milik pengguna. Semua dijadikan baseline, tidak diganti dengan ZIP lama. Mesin AI dan kontrak API tetap digunakan.

CI baseline run `37947909741`: AI lulus; Flutter analyze gagal pada 7 lint; Laravel gagal pada 6 dari 10 tes karena `consents.user_id` tidak tersimpan. Akar masalah: `firstOrNew` melakukan mass assignment atas kolom ownership yang dilindungi. Perbaikan harus menetapkan ownership dari identitas server dengan `forceFill`, bukan membuka mass assignment.

## Pemetaan desain sebelum perubahan

| Gambar V2 | Kondisi awal | Implementasi yang diperlukan |
|---|---|---|
| splash screen | Logo sederhana | Komposisi logo hati, lingkaran, status pemuatan |
| welcome screen | Teks dan ikon | Hero, kartu dukungan, CTA mulai/masuk |
| onboarding | Belum ada | Tiga langkah, lanjut/lewati, pilih peran |
| login screen | Form dasar | Header, label, tampilkan sandi, ingat sesi |
| beranda_pasien | Kartu berbeda | Check-in utama, AI, jadwal, tren, aktivitas |
| chek in harian | Form fungsional | Selektor bernomor, mood, privasi, konfirmasi simpan |
| percakapan_hopely | Bubble putih | Bubble biru/lavender, composer dan saran awal |
| insight emosi pasien | Grafik dasar | Hierarki insight, grafik, skor, CTA laporan |
| jurnal harian | Daftar dasar | Kartu privat, surat harapan, editor |
| profile pasien | Daftar pengaturan | Identitas, jumlah catatan nyata, kerabat, pengaturan |
| tols kesehatan | Belum ada | Hub aktivitas, informasi, jadwal, gejala |
| screen kerebat | Form di dashboard | Layar penerimaan undangan terpisah |
| undang kerabat | Form dasar | Kartu token, salin, daftar dan izin granular |
| dashboard kerabat | Key/value mentah | Ringkasan berizin, skor, jadwal, AI coach |
| dashboar notifikasi darurat kerabaat | Belum ada | Layar alert dari notifikasi nyata dan langkah dukungan |

## Resolusi konflik desain

- Skala tetap **1–5**, termasuk Tools dan dashboard kerabat. Kualitas tidur bukan jam tidur. Grafik hanya data tercatat; tren tetap 7/14 hari, ringkasan dokter tetap 7/14/30 hari.
- Jurnal dan chat tetap privat. Tidak ada tab berbagi jurnal, komunitas, kutipan catatan pasien untuk kerabat, atau tautan publik tanpa autentikasi.
- Undangan tetap token acak 48 karakter, terikat email, kedaluwarsa 48 jam, sekali pakai. Bukan kode pendek/tautan publik. Salin token adalah aksi pengguna; aplikasi tidak otomatis mengirim pesan.
- Notifikasi dukungan bukan pemantauan darurat atau diagnosis. Tidak menampilkan nomor hotline fiktif, nama pasien/angka yang tidak diberikan API, janji 24/7, HIPAA, end-to-end encryption, atau klaim klinis tanpa bukti.
- Tidak menambahkan Google login, audio, rekaman, telepon, atau pesan antar pengguna palsu. Integrasi yang belum memiliki backend/konfigurasi tidak ditampilkan sebagai tombol yang sudah bekerja.
- Navigasi utama konsisten Beranda / Perjalanan / Hopely AI / Insight / Profil. Jurnal dan Tools tersedia lewat Beranda dan Profil; komunitas tetap fase opsional sesuai master requirement.
- Tanpa aset ilustrasi terpisah dari Stitch, hero memakai ilustrasi ikon Flutter yang dapat diskalakan, bukan screenshot seluruh UI sebagai tampilan aplikasi.

Hasil pengujian dan batas verifikasi dicatat setelah implementasi.
