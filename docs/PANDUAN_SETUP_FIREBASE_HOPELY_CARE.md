# Setup Firebase Hopely Care

Konfigurasi resmi harus berasal dari Firebase Console milik pengelola. APK debug berhasil dibangun tanpa konfigurasi Firebase, tetapi itu bukan bukti FCM berfungsi.

1. Daftarkan Android `id.hopely.hopely_care` dan iOS `id.hopely.hopelyCare` pada proyek Firebase yang sama dengan pengirim backend.
2. Unduh Android `google-services.json` ke `mobile/android/app/google-services.json`. Plugin Google Services diterapkan kondisional oleh build Gradle yang sudah tersedia.
3. Unduh iOS `GoogleService-Info.plist`, tambahkan ke target Runner melalui Xcode. Aktifkan Push Notifications dan Background Modes/Remote notifications. Unggah APNs key resmi ke Firebase Console.
4. Dari `mobile`, jalankan `flutter pub get`, kemudian `flutter run --dart-define=FCM_ENABLED=true --dart-define=API_BASE_URL=https://HOST/api`. Ganti HOST dengan backend yang dapat dijangkau perangkat. Konfigurasi native digunakan oleh Firebase.initializeApp; firebase_options.dart tidak wajib bila konfigurasi native lengkap.
5. Pada environment Laravel isi FCM_PROJECT_ID dan GOOGLE_APPLICATION_CREDENTIALS. Yang kedua menunjuk file service account privat di server. Jangan letakkan service account dalam mobile, repository, atau direktori publik.
6. Jalankan scheduler Laravel sesuai deployment. Pengiriman memakai FCM HTTP v1; periksa push_status tanpa mencetak token/payload rahasia.

## Verifikasi perangkat

- Login akun pendamping sintetis, aktifkan izin notifikasi, pastikan POST /api/devices berhasil.
- Buat relasi dan izin SOS melalui pasien sintetis. Kirim SOS dengan konfirmasi.
- Foreground: periksa pemberitahuan, refresh SOS, serta tidak ada duplikasi.
- Background: tekan notifikasi; detail harus berasal dari API terbaru.
- Terminated: tekan notifikasi; tunggu pemulihan sesi sebelum detail dibuka.
- Uji logout, berganti akun, akses dicabut, payload invalid, jaringan terputus, dan permintaan sudah selesai.
- Bandingkan waktu kirim backend, penerimaan FCM provider, dan tampilnya notifikasi perangkat. `provider_accepted` bukan bukti perangkat menerima atau pendamping membaca.

## Diagnosis

`not_configured`: periksa path service account/project backend. `no_device`: periksa registrasi token. `failed`: periksa koneksi dan konfigurasi provider tanpa mencetak secret. Error inisialisasi mobile: cocokkan package/bundle serta target file native. Izin OS ditolak: aktifkan kembali melalui Settings perangkat.

Jangan membagikan service account JSON, private key APNs, bearer token, token FCM, atau INTERNAL_SERVICE_KEY. File konfigurasi aplikasi resmi pun perlu dibagikan hanya melalui kanal pengembangan tepercaya.
