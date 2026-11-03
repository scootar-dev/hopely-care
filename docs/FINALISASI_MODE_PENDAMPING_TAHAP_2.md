# Finalisasi Mode Pendamping Tahap 2

## A. Perubahan selesai

- Pemilih pasien pada dashboard jika lebih dari satu pasien.
- Ringkasan dan Panduan Pendamping tampil langsung di dashboard memakai komponen detail yang sama. Key patientId memisahkan state; perlindungan request dan validasi akses sebelumnya dipertahankan.
- Dialog konfirmasi sebelum caregiver menyelesaikan SOS, dengan Batal/Selesaikan dan status menunggu backend.
- Build Android diperbaiki: konflik cache Kotlin daemon di Windows diatasi dengan `kotlin.incremental=false` dan strategi kompilasi in-process. Firebase tidak dihapus.

## B. Status fitur

| Fitur | Sebelum | Perubahan | Status akhir |
|---|---|---|---|
| Pasien aktif | Kartu navigasi | Dropdown untuk beberapa pasien, state lokal | SEBAGIAN: belum persisten |
| Ringkasan dashboard | Hanya detail | Komponen berizin embedded | SEBAGIAN: belum diringkas menjadi preview pendek |
| SOS resolve | Langsung request | Dialog konfirmasi | SELESAI pada tes lokal |
| Android APK | Gagal cache Kotlin | Non-incremental in-process | BUILD BERHASIL |
| Error undangan | Generik | Belum diubah | BELUM SELESAI |
| Tes khusus retry token | Belum lengkap | Belum ditambahkan | BELUM SELESAI |
| AI live / FCM perangkat | Belum terverifikasi | Panduan proyek dibuat | BELUM TERVERIFIKASI |

## C. File

- `mobile/lib/features/caregiver/caregiver_screen.dart`: pemilih dan ringkasan embedded.
- `mobile/lib/features/caregiver/quick_help_screen.dart`: dialog resolve.
- `mobile/android/gradle.properties`: workaround cache Kotlin.
- `mobile/test/caregiver_security_test.dart`: konfirmasi resolve dalam tes.
- `docs/PANDUAN_SETUP_FIREBASE_HOPELY_CARE.md`.
- `docs/PANDUAN_AI_LIVE_HOPELY_CARE.md`.

## D. Build dan pengujian

- `flutter pub get`: dijalankan; dependensi terselesaikan.
- `flutter analyze`: No issues found.
- `flutter test`: 71 tes lulus setelah perubahan terakhir.
- `flutter build apk --debug`: awalnya gagal pada cache incremental firebase_core/image_picker_android. Setelah perbaikan Gradle, berhasil menghasilkan `mobile/build/app/outputs/flutter-apk/app-debug.apk`.
- Build berhasil dilakukan sebelum penambahan dialog resolve terakhir; perubahan Dart terakhir sudah analyze/test tetapi APK belum dibangun ulang setelahnya.
- Peringatan kompatibilitas KGP firebase_core untuk versi Flutter mendatang masih muncul; bukan kegagalan build saat ini.
- Backend/FastAPI tidak diubah pada tahap ini; PHPUnit/FastAPI tidak dijalankan ulang. Tidak ada klaim end-to-end dua akun/perangkat nyata.

## E. AI live dan FCM

Konfigurasi Settings FastAPI diperiksa, provider default Groq. Provider live belum dipanggil pada tahap ini, sehingga tidak dinyatakan berhasil maupun dinyatakan pasti tidak memiliki credential. Firebase native dan penerimaan perangkat juga belum diverifikasi. Panduan menjelaskan konfigurasi native, environment backend, metadata live/mock, dan bukti penerimaan perangkat yang harus dipisahkan dari penerimaan provider.

## F. UI/UX dan aksesibilitas

Dropdown memakai label dan isExpanded; satu pasien tidak diberi dropdown. SOS tetap di luar proses load dashboard sehingga kegagalan dashboard tidak menyembunyikannya. Dashboard saat ini masih menampilkan SOS sebelum blok header/pemilih dan dapat terlalu panjang karena seluruh Coach/ringkasan embedded. Review manual teks besar, screen reader, seluruh orientasi belum dilakukan.

## G. Pekerjaan belum selesai

Persistensi pilihan pasien, penghapusan pilihan saat relasi dicabut, penyegaran daftar relasi berkala, susunan dashboard final dan preview ringkas, mapping error undangan, delapan skenario khusus retry token, review perangkat, AI live, FCM nyata, dan end-to-end masih perlu diselesaikan. Ini mencakup pekerjaan kode yang belum selesai, bukan semuanya tindakan manual pengguna.

## H. TINDAKAN MANUAL YANG HARUS DILAKUKAN PENGGUNA

1. **Sediakan konfigurasi Firebase resmi.** Memerlukan kepemilikan akun Firebase yang tidak dapat dibuat atas nama pengguna secara otomatis. Ikuti `PANDUAN_SETUP_FIREBASE_HOPELY_CARE.md`: unduh file native ke lokasi yang ditentukan, atur APNs dan environment backend, lalu jalankan build dengan FCM_ENABLED=true. Bukti sukses harus mencakup notifikasi benar-benar terlihat pada perangkat. Jangan bagikan service account/private key/token.
2. **Sediakan perangkat untuk verifikasi.** Sambungkan Android dengan USB debugging atau iOS melalui lingkungan Xcode. Periksa `flutter devices`, lalu `flutter run` dengan konfigurasi API dan FCM yang sesuai. Verifikasi foreground/background/cold start, logout dan pencabutan izin. Akses perangkat tidak dapat disimulasikan sebagai bukti penerimaan push nyata.
3. **Konfirmasi akses provider AI resmi bila diperlukan.** Ikuti `PANDUAN_AI_LIVE_HOPELY_CARE.md`; gunakan model yang tersedia pada akun pengelola dan data sintetis. Verifikasi metadata serta request provider nyata. Jangan kirim API key atau internal service key dalam percakapan/log publik. Pengujian live yang dapat dilakukan menggunakan konfigurasi workspace masih merupakan tindak lanjut pengembang, bukan kewajiban pengguna menjalankan ulang seluruh audit.
