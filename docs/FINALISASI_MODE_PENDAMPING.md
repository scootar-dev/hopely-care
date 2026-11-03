# Finalisasi Mode Pendamping Hopely Care

## A. Ringkasan

Penyempurnaan bertahap diterapkan pada dashboard, ringkasan berizin, Panduan Pendamping, informasi SOS, unread badge, sinkronisasi nama akun, dan retry registrasi FCM. Perlindungan invalidasi data, race condition, serta isolasi SOS sebelumnya tetap lulus regresi.

Status keseluruhan: **SEBAGIAN**. Aplikasi belum dinyatakan siap demonstrasi push nyata. Konfigurasi resmi Firebase dan verifikasi perangkat masih diperlukan; beberapa penyempurnaan UI juga masih tercatat di bagian terakhir.

## B. Perubahan halaman

| Halaman | Masalah sebelumnya | Perbaikan | Status |
|---|---|---|---|
| Dashboard pendamping | Sapaan tanpa identitas, kartu dekoratif, tujuan kartu pasien kurang jelas | Sapaan nama akun, pengurangan kartu dekoratif, petunjuk memilih pasien, label hubungan terhubung, akses komunitas | SEBAGIAN: belum ada pemilih pasien aktif persisten dan ringkasan inline dashboard |
| Ringkasan pasien | Kelompok informasi kurang mudah dipahami; jadwal kosong tidak jelas | Label kondisi emosional/fisik, penjelasan izin tiap kelompok, empty state jadwal | SELESAI untuk perubahan ini; pesan pencabutan akses masih memakai error bersama |
| Coach | Judul kurang langsung | Judul Panduan Pendamping dan deskripsi singkat; form/jawaban serta validasi akses dipertahankan | SELESAI untuk perubahan ini; AI live belum diverifikasi |
| Care Circle | Daftar pasien tidak menjelaskan tujuan akses | Label hubungan dan akses ringkasan/panduan diperjelas; kode undangan tetap mekanisme nyata | SEBAGIAN: error kode undangan spesifik belum ditambahkan |
| Bantuan Cepat | Waktu/status kurang eksplisit | Waktu permintaan jika tersedia dan label status yang tidak hanya bergantung warna | SEBAGIAN: konfirmasi tambahan resolve belum diterapkan; cancel tetap RESOLVED secara historis |
| Notifikasi | Tidak ada jumlah unread global | Endpoint count owner-scoped dan badge dashboard; inbox memuat ulang saat event push/read | SELESAI untuk pembaruan kode; push nyata belum diverifikasi |
| Profil | Nama tersimpan tetapi state lama tetap tampil | Respons PUT /me memperbarui Session.user langsung; identitas akun diperiksa | SELESAI, unit test lulus |

Tidak menambahkan navbar caregiver baru. Profil tetap avatar. Pemilihan pasien tetap melalui kartu yang membuka halaman pasien terkait.

## C. File perubahan tahap finalisasi

- `mobile/lib/features/caregiver/caregiver_screen.dart`: sapaan, akses pasien/komunitas, label izin, kelompok ringkasan, Coach.
- `mobile/lib/features/caregiver/quick_help_screen.dart`: waktu dan label status.
- `mobile/lib/core/notifications/notification_action.dart`: badge jumlah unread global.
- `mobile/lib/core/notifications/push_service.dart`: retry registrasi maksimal empat percobaan, jeda 1/2/4 detik, invalidasi generasi saat detach/logout.
- `mobile/lib/core/api/api.dart`: Session.updateAccount menolak identitas akun berbeda.
- `mobile/lib/features/settings/settings_screen.dart`: penerapan respons nama akun ke Session.
- `mobile/android/settings.gradle.kts`: deklarasi plugin Google Services.
- `mobile/android/app/build.gradle.kts`: plugin Google Services hanya diterapkan jika konfigurasi Android tersedia.
- `backend/routes/api.php`: GET /api/notification-count.
- `backend/app/Http/Controllers/NotificationController.php`: jumlah unread milik akun, tanpa batas 50 item.
- `backend/tests/Feature/SupportAlertTest.php`: assertion unread setelah read.
- `mobile/test/caregiver_finalization_test.dart`: perubahan nama dan penolakan akun berbeda.
- `mobile/test/caregiver_security_test.dart`: interaksi keyboard/scroll sebelum aksi Coach.

## D. Status FCM dan konfigurasi

| Lapisan | Status |
|---|---|
| Kode lifecycle foreground/background/cold start | Tersedia dari tahap sebelumnya |
| Retry registrasi token | Ditambahkan; maksimal empat percobaan, hanya Dio network/429/5xx, berhenti saat generasi/sesi berubah |
| Simulasi routing/payload/read/akun | Lulus dalam suite Flutter |
| Pengujian khusus waktu retry/rotasi SDK | Belum dilakukan |
| Konfigurasi Firebase native | Belum tersedia pada pemeriksaan sebelumnya; tidak dibuat credential palsu |
| Plugin Android | Deklarasi ditambahkan; build Gradle dengan Firebase belum diverifikasi |
| Pengiriman backend ke FCM | Implementasi HTTP v1 tersedia, belum diverifikasi dengan credential nyata |
| Push diterima perangkat | Belum diverifikasi |
| Tap background dan cold start perangkat | Belum diverifikasi |

### Konfigurasi resmi yang diperlukan

1. Daftarkan aplikasi Android pada proyek Firebase resmi dengan package **`id.hopely.hopely_care`**, sesuai `mobile/android/app/build.gradle.kts`. Letakkan file unduhan resmi pada `mobile/android/app/google-services.json`. Tidak ditemukan konfigurasi flavor khusus pada file build yang diperiksa.
2. Daftarkan aplikasi iOS dengan bundle ID **`id.hopely.hopelyCare`**, sesuai `mobile/ios/Runner.xcodeproj/project.pbxproj`. Tambahkan `GoogleService-Info.plist` melalui Xcode ke target Runner, aktifkan Push Notifications serta Background Modes → Remote notifications, dan konfigurasi APNs resmi di Firebase.
3. Inisialisasi saat ini menggunakan konfigurasi native `Firebase.initializeApp()`. `firebase_options.dart` bukan syarat jika konfigurasi native lengkap; jangan membuat isinya secara manual menggunakan credential palsu.
4. Jalankan build mobile dengan `--dart-define=FCM_ENABLED=true` dan API_BASE_URL yang dapat dijangkau perangkat. Gunakan build tanpa flag tersebut bila Firebase belum dikonfigurasi.
5. Pada Laravel, isi **FCM_PROJECT_ID** dan **GOOGLE_APPLICATION_CREDENTIALS**. Nilai kedua harus menunjuk file service account di lokasi server privat, bukan di repository atau direktori publik. Kontrak ada pada `backend/config/services.php`.
6. Pastikan FCM HTTP v1 aktif, IAM pengirim sesuai, koneksi keluar tersedia, dan scheduler Laravel berjalan untuk retry notifikasi. Jangan mencetak credential/token dalam log demonstrasi.

### Checklist perangkat sebelum demonstrasi

- Gunakan akun pasien/pendamping sintetis dan relasi berizin.
- Uji izin OS ditolak, disetujui, dan dicabut kembali.
- Pastikan token terdaftar sekali; uji rotasi, jaringan terputus, retry, logout saat registrasi tertunda, dan pergantian akun.
- Kirim SOS; periksa record backend, penerimaan provider, dan penerimaan perangkat sebagai tiga bukti berbeda.
- Uji foreground: satu pemberitahuan dan refresh SOS; jangan duplikat notifikasi OS/local.
- Uji background dan terminated: tap membuka SOS tepat setelah sesi siap.
- Uji akun logout/berbeda, hubungan dicabut, izin dicabut, notifikasi duplikat, dan payload invalid.
- Buka notifikasi SOS yang sudah selesai; pastikan tidak tersedia aksi menyelesaikan ulang.
- Uji read gagal tanpa menghalangi akses SOS; periksa unread count setelah read berhasil.
- Rekam hasil perangkat, OS, build, status jaringan, dan waktu; jangan mengklaim sukses hanya dari respons provider.

## E. Pengujian aktual

| Perintah | Hasil |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | **71 tes lulus** |
| `php vendor/bin/phpunit --do-not-cache-result --filter "SupportAlertTest|PrivacyTest|CaregiverInvitationTest|CompletionRegressionTest"` | **22 tes, 108 assertions lulus** |

Percobaan awal menemukan tes Coach mengetuk tombol di luar viewport setelah penambahan informasi izin. Helper tes diperbaiki dengan unfocus keyboard dan menunggu scroll selesai; suite lengkap kemudian lulus. Pemeriksaan statis awal menemukan dua lint braces, sudah diperbaiki.

Tes Flutter memakai fixture; PHPUnit memakai database pengujian. Tidak menguji data kesehatan nyata. FastAPI tidak diubah sehingga tes FastAPI tidak dijalankan ulang. Suite mencakup rendering halaman caregiver, navigasi, privasi, SOS independen, profil, dan push simulasi; bukan pemeriksaan visual manual lengkap untuk semua ukuran layar/orientasi.

## F. Risiko dan batasan

Validasi akses aktif masih periodik 60 detik, dengan validasi tambahan pada navigasi/resume/refresh/Coach. Tidak ada push pencabutan izin real-time. Retry registrasi dibatasi dan tidak mengubah otorisasi backend. Endpoint count global benar-benar menghitung seluruh notifikasi akun, bukan 50 item inbox.

Mode AI live belum dibuktikan pada sesi ini. MockNotice tetap mengikuti metadata respons. Pembatalan historis tetap tidak dibedakan dari penyelesaian karena backend menyimpan RESOLVED; tidak ada migration yang mengarang status historis.

## G. Daftar final pekerjaan tersisa

| No | Masalah yang masih tersisa | Penyebab | Yang dibutuhkan | Prioritas |
|---|---|---|---|---|
| 1 | Firebase nyata belum terverifikasi | Konfigurasi resmi/perangkat belum tersedia | File konfigurasi resmi, credential server privat, APNs dan perangkat | P1 |
| 2 | Build Android dengan plugin baru belum diverifikasi | Belum menjalankan build native | Build Android dan pemeriksaan kompatibilitas Gradle/Google Services | P1 |
| 3 | Retry token belum memiliki tes waktu/rotasi SDK khusus | Suite baru menguji logika push/routing dan backend | Tes fake-time dan perangkat, termasuk logout saat request sedang berlangsung | P1 |
| 4 | Pemilih pasien aktif persisten dan ringkasan dashboard inline belum dibuat | Dashboard tetap daftar pasien dengan akses detail | State pemilihan pasien dengan invalidasi aman dan widget test | P2 |
| 5 | Konfirmasi resolve tambahan dan error undangan lebih spesifik | Interaksi lama masih dipertahankan | Dialog resolve dan mapping error konteks | P2 |
| 6 | Refresh inbox dari push nyata belum diverifikasi | Listener sudah tersedia; perangkat Firebase belum tersedia | Uji pesan foreground ketika inbox terbuka | P2 |
| 7 | Layout seluruh ukuran/orientasi belum diverifikasi manual | Tes rendering bukan pengujian perangkat lengkap | Review layar kecil/besar, teks besar, keyboard, TalkBack/VoiceOver | P2 |
| 8 | Kualitas Coach live belum diverifikasi | Provider nyata belum diuji pada sesi ini | Skenario sintetis dan pemeriksaan metadata/safety | P1 sebelum demo AI live |
