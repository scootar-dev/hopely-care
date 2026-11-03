# Audit Mode Pendamping Hopely Care — Backend vs Flutter

Tanggal: 2 November 2026. Lingkup: audit kode dan pengujian lokal; tidak mengubah kode aplikasi. Perubahan aplikasi dari pekerjaan sebelumnya tetap ada dalam workspace. Pengujian dapat menghasilkan cache, log, dan gambar review.

## A. Ringkasan Mode Pendamping

Mode Pendamping memiliki fungsi nyata, bukan dashboard statis. Registrasi/login berbasis peran, penerimaan kode undangan, daftar beberapa pasien, ringkasan berizin, Caregiver AI Coach, daftar SOS aktif, tanggapan/penyelesaian SOS, notifikasi dalam aplikasi, profil/foto, dan komunitas sudah memiliki jalur Flutter–Laravel.

Tidak ditemukan endpoint inti pendamping yang sama sekali tidak dipanggil Flutter. Gap dominan adalah **perilaku endpoint yang belum lengkap di UI**, penanganan push, pembaruan data setelah pencabutan izin, dan sinkronisasi profil. Jangan membuat ulang halaman Coach atau ringkasan yang sudah tersedia.

Kesiapan produksi belum dapat dinyatakan: belum diuji Flutter–Laravel–FastAPI–model hidup secara bersamaan, FCM nyata belum diuji, dan tes belum mencakup seluruh race condition pencabutan izin. Tidak ditemukan bukti langsung endpoint jurnal/chat membocorkan data kepada pendamping; ada risiko data lama tetap terlihat di layar setelah izin dicabut.

### Sumber kebutuhan

`docs/proposal_hopelycare.docx` berhasil dibaca langsung sebagai ZIP OOXML melalui Python `zipfile` dan `xml.etree.ElementTree`, tanpa mengubah dokumen. Rujukan:

- **Tujuan/Manfaat:** keterlibatan keluarga melalui Care Circle, Coach, Bantuan Cepat; informasi sesuai persetujuan.
- **Ekosistem Dukungan Sosial:** pasien menentukan informasi tiap pendamping; Coach memakai konteks yang diizinkan tanpa jurnal/chat pribadi.
- **Informasi Kesehatan dan Keselamatan:** konfirmasi sebelum SOS; bedakan tercatat, pemberitahuan terkirim, tanggapan; jelaskan kegagalan dan layanan darurat.
- **Privasi, Keamanan, dan Pengelolaan Sistem:** persetujuan, pembatasan akses, notifikasi, pembagian peran.
- **Mekanisme Pendampingan AI Kontekstual:** konteks relevan dan berizin, batasan nonklinis.
- **Uraian Peran:** pendamping memberi dukungan, bukan administrator.

Proposal tidak merinci kewajiban inbox undangan, penolakan undangan, pendamping memutus hubungan sendiri, riwayat SOS, atau akses raw check-in. Ketidaktersediaannya dicatat, bukan dianggap endpoint backend tersembunyi. Aturan audit lebih ketat tentang jurnal/chat tetap digunakan.

### Peta bukti

| Kode | File / fungsi utama |
|---|---|
| B1 | `backend/routes/api.php:13-99`: autentikasi, role, caregiver, SOS, notifications |
| B2 | `backend/app/Http/Controllers/CaregiverController.php:11-152`: invite, accept, index, permissions, revoke, patients, summary, coach |
| B3 | `backend/app/Services/CaregiverService.php:13-78`: hubungan accepted, consent, agregat berizin |
| B4 | `backend/app/Http/Controllers/SupportAlertController.php:10-95`: recipients, visible, data, active, store, transition |
| B5 | `backend/app/Http/Controllers/NotificationController.php:7-37`: daftar, read, device, removeDevice |
| B6 | `backend/app/Services/NotificationService.php:8-143`: push, retryPending, supportAlert |
| B7 | `backend/app/Http/Controllers/AuthController.php:11-95`: register, login, me, account, logout, destroy |
| B8 | `backend/app/Services/AiClient.php:7-30`; `backend/app/Services/AiApplicationService.php:150-152` |
| F1 | `mobile/lib/features/caregiver/caregiver_screen.dart`: CaregiverScreen, CaregiverConnectScreen, CaregiverPatientScreen |
| F2 | `mobile/lib/features/caregiver/quick_help_screen.dart`: QuickHelpPanel._load/_act/build |
| F3 | `mobile/lib/features/caregiver/support_alert_screen.dart`: pengingat dukungan otomatis, bukan detail SOS manual |
| F4 | `mobile/lib/features/care_circle/care_circle_screen.dart`: undang, salin kode, izin, pencabutan |
| F5 | `mobile/lib/features/settings/settings_screen.dart`: SettingsScreen, NotificationsScreen; `profile_photo.dart` |
| F6 | `mobile/lib/core/routing/router.dart`, `core/api/api.dart`, `core/widgets/account_action.dart` |
| F7 | `mobile/lib/core/notifications/push_service.dart`; `features/stitch_v2/stitch_v2_detail_screens.dart:646-735` |
| F8 | `mobile/lib/core/widgets/ui.dart:185-225`: DataPage loading/error/retry/pull-to-refresh |
| A1 | `ai-service/app/main.py:153-155`; `app/services/engine.py:94-115`; `app/schemas/contracts.py:249-268` |
| A2 | `ai-service/app/llm/provider.py`; `app/core/config.py`; `app/safety/service.py` |

## B. Inventaris Backend Pendamping

Semua endpoint Laravel berikut berawalan `/api`. Status verifikasi berarti cakupan tes yang disebut, bukan jaminan produksi end-to-end.

| No | Kemampuan Backend | Endpoint | Controller/Service | Status | Bukti |
|---|---|---|---|---|---|
| 1 | Registrasi pasien/pendamping, login | POST `/auth/register`, `/auth/login` | AuthController | ADA TETAPI BELUM TERVERIFIKASI untuk seluruh alur caregiver | B7; penolakan admin diuji |
| 2 | Profil, ubah nama, logout, hapus akun | GET/PUT/DELETE `/me`; POST `/auth/logout` | AuthController | IMPLEMENTASI SEBAGIAN pada sinkronisasi UI nama | B7, F5; CompletionRegressionTest |
| 3 | Foto pribadi | GET/POST/DELETE `/me/avatar` | ProfilePhotoController, ProfilePhotoService | SELESAI DAN TERVERIFIKASI pada tes lokal | ProfilePhotoTest; profile_photo_test.dart |
| 4 | Pemulihan kata sandi | POST `/auth/forgot-password`, `/auth/reset-password` | PasswordController | ADA TETAPI BELUM TERVERIFIKASI dalam audit ini | B1; UI `features/auth/password_screen.dart` |
| 5 | Persetujuan milik akun | GET/PUT `/consents` | ConsentController, ConsentService | SELESAI DAN TERVERIFIKASI pada consent owner/revoke | PrivacyTest; F5 PrivacyScreen |
| 6 | Membuat kode undangan 48 jam | POST `/caregivers/invite` | CaregiverController::invite | SELESAI DAN TERVERIFIKASI pada alur dasar | B2, F4; CaregiverInvitationTest |
| 7 | Menerima kode email-terikat satu kali | POST `/caregivers/accept` | CaregiverController::accept | SELESAI DAN TERVERIFIKASI pada alur dasar | B2:59-77; F1:163-186; tes backend dan Flutter |
| 8 | Daftar relasi pasien, lima izin, revoke | GET `/caregivers`; PUT `/caregivers/{id}/permissions`; DELETE `/caregivers/{id}` | CaregiverController | IMPLEMENTASI SEBAGIAN pada penyegaran layar pendamping | B2:79-115, F4, B3 |
| 9 | Daftar pasien accepted | GET `/caregiver/patients` | CaregiverController::patients | SELESAI DAN TERVERIFIKASI pada kontrak dasar | B2:117-130; F1:29-34,107-118 |
| 10 | Agregat wellbeing, gejala, 5 jadwal berikut, jumlah aktivitas | GET `/caregiver/patients/{id}/summary` | CaregiverService | IMPLEMENTASI SEBAGIAN pada invalidasi/empty state UI | B3; F1:328-404; PrivacyTest |
| 11 | Coach berkonteks berizin | POST `/caregiver/patients/{id}/coach` | CaregiverController, AiClient | ADA TETAPI BELUM TERVERIFIKASI end-to-end live | B2:136-152; F1:293-319,405-447; A1 |
| 12 | Coach internal | POST `/v1/ai/caregiver-coach` | FastAPI, Engine.caregiver | ADA TETAPI BELUM TERVERIFIKASI model live | A1/A2; tes akses internal dan penolakan raw chat |
| 13 | Buat SOS pasien, cegah duplikasi aktif | POST `/support-alerts` | SupportAlertController::store | SELESAI DAN TERVERIFIKASI pada lifecycle lokal | B4:52-68; SupportAlertTest; F2 |
| 14 | SOS aktif pasien/pendamping | GET `/support-alerts/active`; GET `/caregiver/support-alerts` | SupportAlertController::active | SELESAI DAN TERVERIFIKASI pada API lokal | B4:40-50; F2 polling 5 detik |
| 15 | Tanggapi, selesaikan, batalkan | POST `/support-alerts/{id}/acknowledge`, `/resolve`, `/cancel` | SupportAlertController::transition | IMPLEMENTASI SEBAGIAN pada status terminal | B4:70-95; F2; cancel dan resolve sama-sama RESOLVED |
| 16 | Daftar 50 notifikasi terbaru, read owner-only | GET `/notifications`; PUT `/notifications/{id}/read` | NotificationController | IMPLEMENTASI SEBAGIAN | B5, F5:482-562; read SOS dilewati |
| 17 | Registrasi/hapus token perangkat | POST `/devices`; DELETE `/devices/{id}` | NotificationController | IMPLEMENTASI SEBAGIAN | B5; F7; hapus token dipakai saat logout |
| 18 | Push FCM, status provider, retry | Bukan API UI; dipicu send dan `hopely:retry-notifications` | NotificationService | TERKENDALA PENGUJIAN perangkat; integrasi Flutter sebagian | B6; `backend/routes/console.php:47-50`; F7 |
| 19 | Pengingat dukungan dari sinyal AI URGENT | Pemicu POST `/ai/chat`; hasil GET `/notifications` | AiApplicationService, NotificationService::supportAlert | ADA TETAPI BELUM TERVERIFIKASI live | B8; B6:116-143; F1/F3 sudah menampilkan |
| 20 | Komunitas untuk caregiver (tambahan relevan) | Lihat daftar lengkap berikut | CommunityController, CommunityContentController, CommunitySafetyController | ADA TETAPI BELUM TERVERIFIKASI khusus role caregiver end-to-end | `routes/community.php`, repository dan UI komunitas Flutter |

### Inventaris endpoint komunitas tambahan

`backend/routes/community.php` mengizinkan CAREGIVER, dengan otorisasi keanggotaan/moderasi lanjutan:

- GET `/communities`, `/community/home`, `/community/my-communities`, `/community/preferences`, `/community/safety`, `/community/moderation`, `/community/feed`.
- PUT `/community/preferences`.
- GET `/communities/{community}`, `/communities/{community}/posts`, `/community/posts/{post}`, `/community/posts/{post}/image`, `/community/posts/{post}/comments`.
- POST `/communities/{community}/join`, DELETE `/communities/{community}/leave`.
- POST `/communities/{community}/posts`, PUT/DELETE `/community/posts/{post}`.
- POST/DELETE `/community/posts/{post}/reactions`; POST `/community/posts/{post}/comments`; DELETE `/community/comments/{comment}`.
- POST `/community/reports`, POST/DELETE `/users/{user}/block`, POST `/community/moderation/{kind}/{id}`.

Frontend tersedia melalui `mobile/lib/features/community/data/community_repository.dart` dan `presentation/`; akses dari Profil → Support Circle. Endpoint moderasi tidak berarti semua pendamping memiliki hak moderator. Tidak ditemukan alasan memasukkan seluruh komunitas sebagai fitur hilang.

### Penyimpanan, kebijakan, scheduler

- `backend/database/migrations/2026_10_07_000001_create_hopely_schema.php`: caregiver_links, caregiver_permissions, notifications, device_tokens; unique pasangan pasien/email dan hash kode; izin default false.
- `2026_10_22_000001_create_support_alerts.php`: support_alerts dan support_alert_recipients.
- `2026_10_29_000001_add_notification_delivery.php`: pelacakan pengiriman push.
- Model: `CaregiverLink.php`, `CaregiverPermission.php`, `SupportAlert.php`, `CareNotification.php`, `DeviceToken.php`. Lima izin di-cast boolean.
- `Http/Middleware/RequireRole.php` dan `RequireHealthConsent.php`; `Policies/OwnedRecordPolicy.php` mewajibkan role PATIENT dan pemilik record, tanpa pengecualian admin.
- SOS memeriksa current relationship/permission pada controller; bukan sekadar tombol Flutter.
- Push memakai callback `DB::afterCommit`, bukan bukti adanya worker antrean pengiriman. Retry lewat scheduler setiap lima menit; `emergency_support_update` dan `support_alert` tidak termasuk jenis retry yang diizinkan saat ini.

## C. Matriks Perbandingan Backend dan Frontend

| No | Fitur | Kebutuhan Proposal | Backend | Frontend | Integrasi | Status | Bukti |
|---|---|---|---|---|---|---|---|
| 1 | Autentikasi caregiver, sesi dan guard | Dua mode/peran | Ada | AuthScreen, Session, router | Token secure storage, role redirect | ADA TETAPI BELUM TERVERIFIKASI seluruh lifecycle nyata | B1/B7/F6 |
| 2 | Belum punya pasien | Relevan onboarding | Daftar kosong | Pesan kosong + Hubungkan | Nyata | SELESAI DAN TERVERIFIKASI pada rendering fixture | F1:99-125 |
| 3 | Undang dan terima kode | Care Circle | Ada | Kedua sisi ada | Nyata | SELESAI DAN TERVERIFIKASI lokal | B2/F1/F4 |
| 4 | Inbox undangan, tolak undangan | Tidak eksplisit | Tidak ada endpoint | Tidak ada | Tidak ada | BELUM ADA DI KEDUANYA | B1/B2; accept hanya token |
| 5 | Email/push undangan otomatis | Tidak eksplisit | Tidak dipanggil invite | UI menyuruh salin/kirim pribadi | Manual, bukan gagal integrasi | BELUM ADA DI KEDUANYA untuk pengiriman otomatis | B2:54-57; F4:116-118,165-211 |
| 6 | Multi-pasien | Selaras Care Circle | Daftar accepted | Kartu tiap pasien | Path memuat patientId | SELESAI DAN TERVERIFIKASI kontrak dasar; pergantian multi-pasien perlu tes khusus | B2/F1 |
| 7 | Pasien ubah izin/revoke | Wajib | Ada | CareCircleScreen | Nyata | IMPLEMENTASI SEBAGIAN pada invalidasi UI pendamping | B2/B3/F4/F8 |
| 8 | Pendamping putus hubungan sendiri | Tidak eksplisit | Tidak ada endpoint caregiver | Tidak ada | Tidak ada | BELUM ADA DI KEDUANYA | DELETE caregivers dibatasi PATIENT |
| 9 | Wellbeing, gejala, jadwal, aktivitas berizin | Wajib sesuai izin | Semua empat kelompok ada | Semua empat ditampilkan | Nyata | IMPLEMENTASI SEBAGIAN pada empty/refresh/identitas pasien detail | B3/F1:338-404 |
| 10 | Check-in terakhir/raw history/grafik tren caregiver | Tidak diwajibkan raw data | Tidak ada endpoint caregiver khusus | Tidak ada | Tidak ada | BELUM ADA DI KEDUANYA | Summary hanya agregat 7 hari dan jadwal berikut |
| 11 | Doctor Visit Summary caregiver | Proposal untuk pasien/konsultasi | Endpoint PATIENT saja | Tidak tersedia bagi caregiver | Pembatasan benar | BELUM ADA DI KEDUANYA sebagai akses caregiver | B1:48-89 |
| 12 | Coach tanya/jawab/loading/error/retry | Wajib | Ada | Form dan 3 bidang jawaban, tombol dapat dicoba ulang | Nyata | ADA TETAPI BELUM TERVERIFIKASI live | B2:136-152/F1:293-447/A1 |
| 13 | Mock disclosure AI | Transparansi | metadata.mode | MockNotice dipakai | Ada | SELESAI DAN TERVERIFIKASI komponen; mode runtime belum dibuktikan | F1:434; widget_test tersedia, bukan dijalankan pada audit ini |
| 14 | SOS konfirmasi pasien | Wajib | Ada | Dialog lalu POST | Nyata | SELESAI DAN TERVERIFIKASI lokal | F2; quick_help_test.dart |
| 15 | Caregiver baca/tanggapi/selesai SOS | Wajib/penyelesaian tambahan | Ada | QuickHelpPanel caregiver | Nyata | ADA TETAPI BELUM TERVERIFIKASI UI caregiver aksi penuh | F1:42/F2; API lifecycle diuji |
| 16 | Riwayat SOS, beda batal vs selesai | Status penting; riwayat tidak eksplisit | Active-only; terminal RESOLVED untuk keduanya | Hilang dari daftar aktif | Tidak lengkap di kedua sisi | IMPLEMENTASI SEBAGIAN | B4:42,80-85; F2._load |
| 17 | Notifikasi in-app dan read | Wajib | Ada | Inbox + detail pengingat | SOS tap melewati read | IMPLEMENTASI SEBAGIAN | F5:518-535 |
| 18 | Jumlah unread global | Tidak eksplisit | Tidak ada count endpoint; read_at pada 50 terbaru | Ikon per item, tanpa badge count | Bisa count subset, bukan total | IMPLEMENTASI SEBAGIAN | B5:10-13/F1:20-23/F5 |
| 19 | FCM foreground dan tap/cold start | Mendukung pemberitahuan | Provider + notification_id ada | Registrasi token saja | Handler tidak ada | BACKEND ADA, FRONTEND BELUM TERHUBUNG | B6:60-64/F7; pencarian listener nihil |
| 20 | Perubahan relasi/izin sebagai notifikasi | Tidak eksplisit | Tidak ditemukan send pada mutation | Tidak ada | Tidak ada | BELUM ADA DI KEDUANYA | B2:96-115 |
| 21 | Profil/foto/avatar/logout/hapus akun | Pengelolaan akun | Ada | Avatar kanan atas; settings | Nyata | IMPLEMENTASI SEBAGIAN pada refresh nama | B7/F5/F6 |
| 22 | Komunitas pendamping | FITUR BACKEND TAMBAHAN | Ada | Akses dari Profil, repository/UI tersedia | Nyata | ADA TETAPI BELUM TERVERIFIKASI role-specific | routes/community.php; F5:327-332 |

### Alur end-to-end yang ditelusuri

1. **Hubungkan:** `CaregiverConnectScreen.accept` → Riverpod `apiProvider` → `Api.post('/caregivers/accept')` → role CAREGIVER → `CaregiverController.accept` → hash token + email + pending + expiry + lock → caregiver_links accepted → `/caregiver` → GET patients.
2. **Ringkasan:** tap kartu pasien → `/caregiver/{patientId}` → `CaregiverPatientScreen` → DataPage/API summary → `CaregiverService.link/summary` → consent + lima permission → agregat DB → ScoreBar/jadwal/aktivitas. Tidak memakai endpoint pasien untuk mengambil data mentah.
3. **Coach:** tombol Minta saran → `ask()` → POST coach dengan message saja → Laravel menyusun konteks server-side → AiClient internal key → FastAPI strict schema → safety → provider structured → pemeriksaan output → Laravel memeriksa ulang konteks → Flutter tiga teks + metadata. PatientId dan permissions dikeluarkan dari payload AI.
4. **SOS:** menu pasien membuka halaman → konfirmasi → POST support-alerts → lock user/dedupe aktif → penerima accepted+izin → record recipient + notification → FCM afterCommit. Dashboard caregiver polling GET caregiver/support-alerts → nama pasien/status → acknowledge/resolve → backend cek visible lagi.
5. **Notifikasi:** GET notifications milik akun → inbox → support_alert membuka detail pengingat; emergency_support membuka dashboard. Cabang emergency return sebelum PUT read. Push hanya membawa notification_id, belum ada handler Flutter untuk memakainya.
6. **Profil:** AccountAction → `/profile` → GET me melalui Session saat restore/auth → PUT me untuk nama / API avatar untuk foto. PUT nama berhasil tetapi state Session.user tidak diperbarui.

### Kasus batas Care Circle

- Kode kedaluwarsa ditolak oleh `expires_at > now()`; kode digunakan dihapus hash-nya dan tidak dapat dipakai ulang.
- Email akun harus sama dengan invited_email. Role pasien/admin tidak dapat menerima melalui endpoint caregiver.
- Undangan untuk email belum terdaftar diizinkan. Pengiriman kode tetap manual.
- Undangan ulang pending/revoked mengganti token dan mereset semua izin ke false; relasi accepted memberi 409. UI error masih umum, bukan penjelasan tiap kasus.
- Daftar pasien hanya accepted. Revoke menghilangkan akses permintaan API berikutnya.
- Tidak ada endpoint daftar undangan masuk, decline, caregiver-leave, atau riwayat undangan. Jangan memasukkannya sebagai gap frontend-only.

## D. Pemeriksaan Privasi dan Keamanan

### Perlindungan yang ditemukan

- **Antarpasien:** summary/coach mencari pasangan caregiver-patient accepted. Unlinked ditolak; tidak menerima context milik pasien dari Flutter.
- **Consent dan izin:** summary mensyaratkan HEALTH_DATA_PROCESSING dan CAREGIVER_WELLBEING_SHARE; masing-masing kelompok data masih diperiksa izin terpisah. Izin alert tidak membuka jurnal/chat.
- **Jurnal/chat/admin:** routes pasien dilindungi role PATIENT dan health.consent; OwnedRecordPolicy memeriksa pemilik. Admin/moderator tidak mendapat bypass otomatis.
- **Coach:** whitelist konteks hanya empat kelompok agregat. StrictModel `extra='forbid'` menolak raw chat. Laravel memeriksa ulang summary setelah respons AI, sehingga perubahan konteks dapat memberi 409 sebelum respons ditampilkan.
- **SOS:** current relationship dan izin dicek saat daftar serta transisi, termasuk setelah hubungan dicabut. Retry emergency memeriksa kembali hubungan/izin dan status ACTIVE.
- **Notifikasi:** daftar/read terikat user; push menggunakan teks generik, tidak memuat jurnal, gejala, nama pasien, atau isi chat. Notifikasi lama tetap ada setelah revoke tetapi payload tampilannya generik.

### Temuan dan risiko

| ID | Prioritas | Temuan | Bukti / dampak / batas verifikasi |
|---|---|---|---|
| SEC-01 | P1 privasi | Ringkasan dan hasil Coach lama tidak otomatis diinvalidasi saat izin/relasi berubah | F8 menyimpan Future sampai refresh manual; F1.coach tetap tersimpan bahkan ketika ask berikutnya gagal. Revoke backend efektif untuk request baru, tetapi layar lama dapat tetap memperlihatkan informasi sebelumnya. Temuan statis, belum direproduksi dua perangkat. |
| SEC-02 | P1 keselamatan | SOS dapat terlewat saat aplikasi foreground atau pengguna mengetuk push | F7 hanya register/token refresh; tidak ada onMessage, onMessageOpenedApp, getInitialMessage, atau handler background. OS dapat menampilkan notifikasi background jika build dikonfigurasi; bukan berarti foreground/tap terintegrasi. |
| SEC-03 | P1 fungsional | Panel SOS tergantung suksesnya load dashboard lain | QuickHelpPanel baru dibuat di builder setelah GET patients dan notifications selesai. Kegagalan salah satu menutup seluruh dashboard termasuk panel SOS, meski endpoint SOS sendiri sehat. |
| SEC-04 | P2 privasi | Respons SOS mengekspos detail model dan identitas pendamping penanggap kepada penerima berizin | B4.data memakai seluruh `toArray()` + acknowledged_name, recipient_count, status agregat push. Tidak ditemukan raw jurnal/chat. Perlu keputusan minimisasi identitas antarpendamping; bukan bukti akses lintas pasien tanpa izin. |
| SEC-05 | P2 | Ketergantungan consent terlalu luas untuk semua summary/Coach | B3 memerlukan CAREGIVER_WELLBEING_SHARE sekalipun hanya treatment/activity diizinkan. Frontend menampilkan kegagalan generik dan Coach ikut tidak tersedia. Kebijakan perlu diperjelas, bukan di-bypass Flutter. |
| SEC-06 | P2 | Cancellation tidak dibedakan dari resolution | B4.cancel dan resolve menyimpan RESOLVED, tanpa cancellation field; UI menghilangkan keduanya dari active. Tidak dapat diperbaiki frontend saja secara andal. |
| SEC-07 | P2 | Retry notifikasi tidak mencakup support_alert/emergency_support_update | B6:94-95. Notifikasi in-app tetap ada, tetapi pembaruan/generic support push gagal tidak memperoleh retry terjadwal. |
| SEC-08 | P2 | Status enable push kurang tegas saat izin OS ditolak | PushService.enable return tanpa hasil ketika permission ditolak; caller tetap memberi pesan pengaturan diperbarui. Tidak membuktikan token terdaftar atau push aktif. |

Tidak ada P0 kebocoran lintas pasien yang **terbukti** dari pemeriksaan dan tes ini. Hal ini bukan sertifikasi keamanan. Race antara pemeriksaan otorisasi dan pengiriman provider, perubahan izin saat layar terbuka, serta seluruh variasi direct API role masih memerlukan pengujian tambahan. Tidak ada permintaan ke data kesehatan nyata dalam audit.

### Status AI nyata versus mock

- Implementasi provider live dan mock sama-sama ada. `ai-service/app/core/config.py` default mock true dan menolak konfigurasi mock pada production.
- Pemeriksaan terbatas flag non-rahasia menemukan `MOCK_AI_MODE=false` pada root `.env` dan `ai-service/.env`; `backend/.env` memuat true. Flag backend bukan bukti mode proses FastAPI yang sedang berjalan.
- Flutter menggunakan endpoint nyata dan MockNotice(metadata), bukan jawaban hardcoded lokal. Mock provider memang menghasilkan respons fixture ketika dipilih.
- Tes AI dijalankan dengan fixture/provider pengujian; hasilnya tidak membuktikan model live aktif atau kualitas klinis respons. Instruksi non-diagnosis/non-resep dan pemeriksaan safety ada dalam kode.

## E. Hasil Pengujian

| Perintah / pemeriksaan | Hasil aktual | Batasan |
|---|---|---|
| Ekstraksi OOXML proposal lewat Python | Berhasil membaca dokumen | Tidak menilai gambar proposal sebagai kebutuhan tambahan |
| `php artisan test --filter="CaregiverInvitationTest\|PrivacyTest\|SupportAlertTest\|CompletionRegressionTest\|ProfilePhotoTest\|AdminWorkspaceTest"` | Gagal: command test tidak tersedia | Dilanjutkan PHPUnit langsung |
| `php vendor/bin/phpunit --filter "CaregiverInvitationTest\|PrivacyTest\|SupportAlertTest\|CompletionRegressionTest\|ProfilePhotoTest\|AdminWorkspaceTest"` | **30 tes, 145 assertions lulus** | SQLite `:memory:` menurut phpunit.xml; bukan MySQL produksi; fixture sintetis |
| `python -m pytest tests/test_engine.py tests/test_functional_completion.py -q -p no:cacheprovider` | Gagal: Python global tidak punya pytest | Dilanjutkan virtualenv proyek |
| `.\.venv\Scripts\python.exe -m pytest tests/test_engine.py tests/test_functional_completion.py -q -p no:cacheprovider` | **38 tes lulus** | Provider fixture; bukan model/FCM nyata |
| `flutter test test/stitch_v2_test.dart test/quick_help_test.dart test/navigation_flow_test.dart test/profile_photo_test.dart` | **22 tes lulus** | Mock API; render dan interaksi lokal, bukan backend live |

Cakupan konkret: undang/accept sekali/revoke/default izin privat; pendamping belum terhubung ditolak; consent revoke; proteksi jurnal pemilik; larangan registrasi admin; lifecycle SOS/multiple recipients/izin/role/no caregiver; profil/foto milik sendiri; guard Flutter caregiver, input kode, rendering halaman caregiver, navigasi profil, konfirmasi SOS pasien.

Belum diuji: login caregiver lengkap lintas layanan, aksi Coach sukses dengan model live, klik acknowledge/resolve melalui UI caregiver melawan backend nyata, FCM foreground/background/cold start, update permission dua perangkat, restart sesi perangkat, MySQL concurrency. `flutter analyze` tidak dijalankan ulang dalam audit ini; hasil pekerjaan sebelumnya bukan bukti baru audit.

## F. Prioritas Perbaikan

- **P0:** tidak ada kebocoran kritis terkonfirmasi. Jika uji dua akun membuktikan respons baru setelah revoke masih terbuka, naikkan menjadi P0 dan hentikan pelepasan fitur terkait.
- **P1:** invalidasi ringkasan/Coach saat izin berubah; integrasi lifecycle push; pastikan panel SOS tidak tergantung pemuatan notifikasi/dashboard lain; verifikasi Coach dan SOS end-to-end nyata.
- **P2:** read SOS, status terminal terlihat, permission/empty state, nonaktifkan token perangkat tanpa logout, sinkronisasi profil, klarifikasi consent semua summary, retry update push dan pemisahan cancel/resolve backend.
- **P3:** badge unread terbatas 50 item dengan label jelas, penjelasan error undangan lebih spesifik, copy pengaturan notifikasi caregiver yang masih membahas jadwal pasien, identitas pasien pada halaman detail.

# DAFTAR FINAL FITUR BACKEND PENDAMPING YANG BELUM ADA DI FRONTEND

Daftar ini berisi gap nyata dan perilaku parsial, bukan menyatakan seluruh fitur induknya hilang. Endpoint Laravel berawalan `/api`.

| No | Fitur / Kemampuan Backend | Endpoint yang Sudah Ada | File Backend | Kondisi Frontend Saat Ini | Komponen Frontend yang Kurang | Prioritas |
|---|---|---|---|---|---|---|
| 1 | Pengiriman push dengan notification_id | POST `/devices`; GET `/notifications`; GET `/caregiver/support-alerts` sebagai tujuan | `app/Services/NotificationService.php`, `app/Http/Controllers/NotificationController.php` | **BACKEND ADA, FRONTEND BELUM TERHUBUNG**: registrasi/token refresh tersedia; penerimaan foreground dan tap/cold-start tidak ada | Handler FCM, pembaruan inbox/panel, navigasi aman berbasis role setelah sesi siap; detail spesifik alert memerlukan kontrak tambahan | P1 |
| 2 | Akses summary/Coach yang mengikuti current permission/revoke | GET `/caregiver/patients/{id}/summary`; POST `/caregiver/patients/{id}/coach` | `app/Services/CaregiverService.php`, `app/Http/Controllers/CaregiverController.php` | **IMPLEMENTASI SEBAGIAN**: data nyata tampil, tetapi snapshot dan coach lama bertahan | Revalidasi saat resume/refresh/pergantian pasien, invalidasi hasil lama saat 403/404/409, indikator akses berubah | P1 |
| 3 | Membaca dan menanggapi SOS aktif secara mandiri | GET `/caregiver/support-alerts`; POST `/support-alerts/{id}/acknowledge`, `/resolve` | `app/Http/Controllers/SupportAlertController.php` | **IMPLEMENTASI SEBAGIAN**: aksi sudah ada, panel tidak muncul bila pemuatan patients/notifications dashboard gagal | State/error/retry SOS terpisah dari data dashboard lain | P1 |
| 4 | Tandai notifikasi SOS sudah dibaca | PUT `/notifications/{id}/read` | `app/Http/Controllers/NotificationController.php` | **BACKEND ADA, FRONTEND BELUM TERHUBUNG** khusus emergency_support/update: tap langsung return; jenis lain sudah read | Pemanggilan read untuk SOS dan sinkronisasi unread, tanpa menyamakannya dengan acknowledge bantuan | P2 |
| 5 | Menampilkan hasil terminal resolve/cancel dari respons | POST `/support-alerts/{id}/resolve`, `/cancel` | `app/Http/Controllers/SupportAlertController.php` | **IMPLEMENTASI SEBAGIAN**: respons non-send diabaikan lalu active reload menghapus kartu | Konfirmasi status RESOLVED lokal berdasarkan respons; jangan mengarang CANCELLED atau riwayat backend | P2 |
| 6 | Informasi permission dan kelompok summary kosong | GET `/caregiver/patients/{id}/summary` | `app/Services/CaregiverService.php` | **IMPLEMENTASI SEBAGIAN**: semua kelompok data sudah ditampilkan, tetapi jadwal kosong tak diberi pesan; alert-only membuat pemeriksaan any-permission menghilangkan pesan tanpa ringkasan | Status izin per kelompok; empty state membedakan tidak diizinkan, belum ada data, dan jadwal kosong | P2 |
| 7 | Nonaktifkan token push milik perangkat tanpa logout — **FITUR BACKEND TAMBAHAN** | DELETE `/devices/{id}` | `app/Http/Controllers/NotificationController.php` | **IMPLEMENTASI SEBAGIAN**: DELETE dipakai logout; pengaturan hanya menyediakan enable | Aksi nonaktifkan pengingat perangkat, hasil permission denied yang akurat; bukan permintaan menambah daftar perangkat server | P2 |
| 8 | Sinkronisasi hasil perubahan nama akun | PUT `/me`; GET `/me` | `app/Http/Controllers/AuthController.php` | **IMPLEMENTASI SEBAGIAN**: dialog PUT tersedia, respons user diabaikan; Session.user tidak di-refresh | Terapkan respons user ke state atau refresh sesi; membuka ulang profil saja tidak menjamin nama baru | P2 |
| 9 | Indikasi unread dari read_at — **FITUR BACKEND TAMBAHAN** | GET `/notifications` | `app/Http/Controllers/NotificationController.php` | **IMPLEMENTASI SEBAGIAN**: status per item ada, badge jumlah tidak ada | Badge dari kumpulan yang dimuat; total global memerlukan perubahan backend karena respons dibatasi 50 | P3 |

**Bukan gap frontend-only:** inbox/decline undangan, caregiver self-unlink, pengiriman undangan otomatis, notifikasi perubahan izin, raw check-in history, grafik tren caregiver, riwayat SOS, dan status CANCELLED terpisah belum memiliki endpoint caregiver yang memadai. Coach, empat kelompok ringkasan, accept kode, multi-pasien, acknowledge/resolve, foto profil, dan komunitas sudah ditemukan; jangan dicantumkan sebagai frontend tidak ada.

## PRIORITAS IMPLEMENTASI FRONTEND MODE PENDAMPING

1. Integrasikan lifecycle push dan akses SOS independen agar permintaan bantuan dapat ditemukan ketika dashboard lain gagal.
2. Revalidasi izin serta hapus ringkasan/hasil Coach usang saat akses berubah atau permintaan ditolak.
3. Lengkapi read SOS dan konfirmasi hasil terminal dengan tetap membedakan dibaca, ditanggapi, dan selesai.
4. Lengkapi empty/permission state dan kontrol push perangkat, termasuk penolakan izin OS.
5. Sinkronkan perubahan nama akun dan indikator unread terbatas respons backend.
6. Verifikasi seluruh jalur prioritas dengan dua akun sintetis, FastAPI live terkontrol, dan perangkat FCM sebelum menyatakan end-to-end selesai.
