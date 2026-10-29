# Audit Fungsional Hopely Care berdasarkan Proposal

Tanggal: 29 Oktober 2026. Ruang lingkup: fungsi, logika bisnis, backend, database, AI, dan keterhubungan aksi pengguna. Tidak mencakup audit visual. Tidak ada kode aplikasi yang diubah, commit, push, migrasi database operasional, atau pengujian menggunakan data pasien nyata.

## A. Ringkasan kondisi aplikasi

**Hopely Care memiliki implementasi substansial, tetapi belum dapat dinyatakan memenuhi seluruh proposal.** Pencatatan pasien, komunitas, izin caregiver, autentikasi, dan layanan AI sudah memiliki jalur implementasi. Kekurangan paling mendesak adalah klaim pengiriman Bantuan Cepat yang tidak didukung status delivery, kelengkapan AI Reflection, kegagalan uji live rekomendasi/ringkasan, kesiapan RAG, serta pengelolaan konten dan peran administrator.

Proposal `docs/proposal_hopelycare.docx` telah dibaca seluruh teksnya menggunakan ekstraksi XML DOCX di memori, mencakup BAB I, seluruh BAB II, BAB III, dan daftar pustaka. Proposal menjadi acuan utama, bukan README atau backlog lama. Dokumen proposal merupakan berkas untracked yang sudah ada sebelum audit dan tidak diubah.

Hasil penting:
- Laravel: **47 tes lulus, 304 assertion**, SQLite in-memory.
- FastAPI: **53 tes lulus**, mayoritas mock/stub; RAG menggunakan Qdrant in-memory dan embedding palsu.
- Flutter: **54 tes lulus** dengan fixture/fake API; ini bukan pengujian perangkat dengan backend nyata.
- Flutter analyze: exit 1, empat temuan lint tingkat info; tidak ditemukan error kompilasi oleh analyzer pada hasil tersebut.
- Konfigurasi FastAPI lokal yang dibaca melalui `Settings()` adalah **live Groq, model `openai/gpt-oss-20b`**, key tersedia tanpa dicetak. Tes pytest secara eksplisit memaksa mock dan tidak menggambarkan mode lokal ini.
- Uji sintetis FastAPI TestClient → provider nyata: Companion, analisis emosi, dan Caregiver Coach mendapat HTTP 200 dengan metadata live. Rekomendasi dan Doctor Summary mendapat 503 `ai_unavailable`; RAG mendapat 503 `service_unavailable`.
- Tidak ada pembuktian end-to-end Flutter → Laravel → MySQL → FastAPI. Health HTTP loopback port 8000/8001/6333 tidak dapat dicapai pada saat pemeriksaan. Docker tidak ditemukan di PATH. Ini bukan bukti bahwa seluruh deployment lain mati.

### Makna status

“SELESAI DAN TERVERIFIKASI” hanya digunakan jika alur utama kebutuhan tersebut mendapat bukti tes memadai, dengan lapisan pengujian disebutkan. Kelulusan unit/component test tidak menyatakan MySQL, push perangkat, atau integrasi penuh sudah lulus. “BELUM LENGKAP” menunjukkan gap konkret atau kegagalan jalur penting; “TERKENDALA VERIFIKASI” menunjukkan hambatan lingkungan. Tidak semua fitur ber-AI diberi label mock: adapter live memang tersedia dan sebagian berhasil dipanggil.

## Acuan dan cakupan kebutuhan proposal

- BAB I Tujuan 1–6: pendampingan kontekstual, pencatatan terintegrasi, analisis/rekomendasi, komunitas aman, keterlibatan caregiver, informasi tepercaya dan persiapan konsultasi.
- BAB I Manfaat: artikel relevan, akses keluarga sesuai izin, pemberitahuan permintaan bantuan, ringkasan untuk tenaga kesehatan.
- BAB II Bahasan Lengkap: seluruh fitur nomor 1–20 pada matriks berikut, mode pasien/pendamping serta administrator/moderator.
- BAB II Mekanisme AI Kontekstual: pemilihan riwayat relevan berdasarkan persetujuan, aktivitas terkurasi, RAG bersumber, batas nonklinis, dan evaluasi dengan versus tanpa konteks.
- BAB II Teknologi: Flutter, Laravel, MySQL, FastAPI, Qdrant dan kontrol akses API.
- BAB II Prediksi Hasil/Tahapan Strategis: uji pencatatan/pembacaan, privasi, konteks AI, sumber, pengiriman bantuan, integrasi, autentikasi dan pengelolaan akun.
- Manfaat klinis, kolaborasi tenaga kesehatan, dan uji coba pengguna merupakan rencana evaluasi, bukan bukti efektivitas aplikasi atau fitur software yang dapat dinyatakan selesai lewat tes unit. Voice chat dan Meaningful Moments tidak ditemukan sebagai kebutuhan eksplisit proposal ini; placeholder voice di aplikasi dicatat sebagai tambahan, bukan gap wajib proposal.

## B. Matriks audit seluruh fitur

Singkatan path: **M**=`mobile/lib/features/`; **C**=`backend/app/Http/Controllers/`; **S**=`backend/app/Services/`; **A**=`ai-service/app/`. Endpoint Laravel di bawah berawalan `/api`. Tabel tidak menganggap keberadaan halaman sebagai bukti selesai.

| Nomor | Fitur | Kebutuhan Proposal | File Implementasi | API/Service | Status | Bukti | Kekurangan |
|---|---|---|---|---|---|---|---|
| 1 | Daily Check-In | Mood, kecemasan, energi, tidur, nyeri dan riwayat | M `checkin/checkin_screen.dart`, `record_history_screen.dart`; C `RecordController.php`; `backend/app/Http/Requests/RecordRequest.php` | CRUD `/checkins`; S `RecordService.php` | ADA TETAPI BELUM TERVERIFIKASI | Form memanggil POST/PUT; validasi 1–5, tanggal, unique user/date; PrivacyTest menguji create, duplicate, invalid score; tes widget menguji payload | Rangkaian CRUD lengkap hingga MySQL/perangkat belum diuji; kelulusan create bukan bukti seluruh operasi |
| 2 | Symptom Tracker | Catat gejala fisik dan perubahan waktu | M `checkin/checkin_screen.dart` mode symptoms, `record_history_screen.dart`; C `RecordController.php` | CRUD `/symptoms` | ADA TETAPI BELUM TERVERIFIKASI | Validasi enam skor, waktu tidak di masa depan; model SymptomLog; konteks AI memakai riwayat user | Belum ada bukti tes lengkap create/read/edit/delete gejala dengan MySQL |
| 3 | Treatment Journey | Jadwal kemoterapi, kontrol, tindakan, riwayat | M `treatment/treatment_screen.dart`, `stitch_v2/stitch_v2_detail_screens.dart`; C `RecordController.php` | CRUD `/treatments`; `backend/routes/console.php` reminders | ADA TETAPI BELUM TERVERIFIKASI | Status scheduled/completed/cancelled; UTC; tes reminder deduplikasi/status/consent lulus; detail memanggil DELETE | CRUD utama dan reminder perangkat belum teruji end-to-end |
| 4 | Hopely AI Companion | Dialog emosional menggunakan riwayat yang diizinkan | M `ai_companion/chat_screen.dart`; S `AiApplicationService.php:105–152`, `ContextService.php`; A `services/engine.py:39–70` | `/ai/chat`, sesi/pesan → `/v1/ai/companion` | ADA TETAPI BELUM TERVERIFIKASI | Live FastAPI→Groq HTTP 200; context user-scoped, 8 pesan terakhir, izin AI_CHAT_CONTEXT; penyimpanan chat tersedia | Belum diuji HTTP Laravel→FastAPI dan penyimpanan MySQL; belum evaluasi kualitas kontekstual berpasangan |
| 5 | Private Journal | Ruang privat menulis pengalaman, pilihan analisis | M `journal/journal_screen.dart`; S `RecordService.php`; model Journal | CRUD `/journals` | ADA TETAPI BELUM TERVERIFIKASI | POST/PUT/DELETE dan pagination Flutter; title/content encrypted; tes akses jurnal akun lain ditolak | CRUD penuh dengan backend nyata belum dibuktikan |
| 6 | AI Reflection | Tema emosional **dan tanggapan reflektif** berdasarkan jurnal, opt-in | M `stitch_v2/stitch_v2_detail_screens.dart:288–370`; C `AiController.php:14–30`; A `emotion/service.py` | `/journals/{id}/analyze`, `/reflection` → `/v1/ai/emotion/analyze` | BELUM LENGKAP | Live klasifikasi emosi HTTP 200; izin global dan per-entry diperiksa; hasil berisi primary_emotion, scores, themes | Tidak ada field/generasi tanggapan reflektif; hanya label/skor/tema. Transformer jika diaktifkan bahkan mengembalikan themes kosong |
| 7 | Emotional Insights | Grafik/ringkasan pola mood, cemas, energi, tidur | M `insights/insights_screen.dart`; A `trend/service.py`; S `AiApplicationService.php:74–89` | `/insights?days=` → `/v1/ai/trend/analyze` | ADA TETAPI BELUM TERVERIFIKASI | Statistik nyata, bukan respons LLM hardcoded; suite AI menguji engine/trend; grafik dan ringkasan metrik terhubung API | Belum integrasi data pasien sintetis lintas stack; statistik bukan validasi klinis |
| 8 | Personalized Support Activities | Pilih aktivitas terkurasi sesuai kondisi | M `activities/activities_screen.dart`; S `AiApplicationService.php:158–216`; A `services/engine.py:72–92` | `/activities/recommended`, `/{id}/complete` → `/v1/ai/recommendations` | BELUM LENGKAP | Input konteks 14 hari, tren dan katalog; ID hasil dibatasi katalog; widget completion lulus | Uji live mengembalikan 503; sebab internal provider belum diisolasi. Seleksi hanya `active`, tidak mensyaratkan `medically_reviewed` |
| 9 | Support Circle | Komunitas berdasarkan pengalaman/kanker/fase/dukungan; cerita, dukungan, komentar | M `community/data/community_repository.dart`, `community/presentation/*`; C `CommunityController.php`, `CommunityContentController.php`; S `CommunityService.php` | `backend/routes/community.php`; communities/join/leave/posts/reactions/comments | SELESAI DAN TERVERIFIKASI | Tes backend membership, ownership, revisi, komentar, reaksi, blok, media; tes Flutter join/post/reaction/report/leave lulus | Terverifikasi pada SQLite dan fake API Flutter, belum perangkat–MySQL. Gap moderasi dinilai terpisah nomor 18 |
| 10 | Care Circle | Hubungkan caregiver dan tentukan akses per pendamping | M `care_circle/care_circle_screen.dart`, `caregiver/caregiver_screen.dart`; C `CaregiverController.php`; S `CaregiverService.php` | invite/accept/list/permissions/revoke, caregiver patients/summary | SELESAI DAN TERVERIFIKASI | Tes undangan sekali pakai, email/role, default privat, revoke, agregat berizin dan caregiver tak terhubung lulus; token hash dan kedaluwarsa 48 jam | Cakupan component SQLite dan widget; belum E2E MySQL. Undangan menggunakan kode yang dibagikan pasien |
| 11 | Caregiver AI Coach | Panduan komunikasi dari data berizin, tanpa jurnal/chat | M `caregiver/caregiver_screen.dart`; C `CaregiverController.php:136–152`; A `services/engine.py:94–115` | `/caregiver/patients/{id}/coach` → `/v1/ai/caregiver-coach` | ADA TETAPI BELUM TERVERIFIKASI | Konteks berasal dari summary tersaring dan diperiksa ulang setelah inference; live endpoint 200 | Live uji memakai konteks kosong, sehingga belum membuktikan personalisasi dari izin caregiver dan integrasi lengkap |
| 12 | Doctor Visit Summary | Ringkas 7/14/30 hari, gejala, kondisi, treatment, pertanyaan konsultasi | M `doctor_summary/summary_screen.dart`, `summary_history_screen.dart`; S `AiApplicationService.php:218–241`; A `services/engine.py:117–164` | POST/GET `/doctor-summary`, GET `/{id}` → `/v1/ai/doctor-summary` | BELUM LENGKAP | Agregasi pasien nyata dalam kode; arsip owner-scoped encrypted; periode dan concerns tersedia | Uji live 503; kegagalan narasi menghalangi seluruh pembuatan ringkasan, tidak ada fallback agregat pada jalur ini |
| 13 | PDF Report Export | Simpan/buka/cetak ringkasan | M `doctor_summary/summary_screen.dart:62–95`, `summary_report.dart` | `pdf` + `Printing.layoutPdf` di perangkat | ADA TETAPI BELUM TERVERIFIKASI | Kode membuat multipage PDF, font lokal, isi dari report, label mock | Belum menghasilkan dan membuka PDF melalui plugin perangkat; bergantung ringkasan berhasil |
| 14 | Trusted Knowledge RAG | Cari sumber terkurasi, jawaban dan rujukan | M `knowledge/knowledge_screen.dart`; C `AdminController.php`; A `rag/service.py` | `/knowledge/query` → `/v1/rag/query`; ingest → Qdrant | BELUM LENGKAP | Qdrant adapter nyata, reviewed filter, metadata sumber, reject citation palsu; tes Qdrant in-memory lulus | Live query 503; `sentence_transformers` tidak tersedia di venv; endpoint Qdrant lokal tidak terjangkau; korpus terkurasi operasional belum terbukti |
| 15 | Bantuan Cepat | Konfirmasi, catat, kirim pemberitahuan, status delivery/acknowledge terpisah, kegagalan jelas, arahan darurat | M `caregiver/quick_help_screen.dart`; C `SupportAlertController.php`; S `NotificationService.php` | POST `/support-alerts`, active, acknowledge/resolve/cancel | BELUM LENGKAP | Tes lifecycle/multi-recipient/permission lulus; dialog konfirmasi dan polling tersedia | Tidak ada delivery status; recipient_count disamakan menerima; gagal push ditelan; teks sukses terlalu pasti; panel tidak menyertakan arahan layanan darurat |
| 16 | Artikel Kesehatan | Daftar dan detail artikel relevan/tepercaya | M `knowledge/article_screen.dart`; C `KnowledgeArticleController.php`, `AdminController.php:8–23` | GET `/knowledge/articles`, `/{id}` | BELUM LENGKAP | Daftar/detail membaca JSON reviewed, ID hash divalidasi; Flutter membuka detail melalui API | Publikasi artikel tergantung ingest AI/Qdrant berhasil; tidak ada alur editorial mandiri/draft/unpublish; belum bukti katalog terkurasi siap digunakan. Artikel disimpan file, bukan MySQL |
| 17 | Privacy & Consent | Kendali pemrosesan kesehatan/AI, sharing caregiver, privat jurnal/chat | M `settings/settings_screen.dart`; S `ConsentService.php`, `ContextService.php`; model/policy | GET/PUT `/consents`, health.consent, ownership Gate | SELESAI DAN TERVERIFIKASI | Tes consent, revoke sinyal, akses lintas jurnal, dua izin analisis dan agregat caregiver lulus; fingerprint mencegah menyimpan inference setelah revisi consent | Belum uji race nyata MySQL; penghapusan turunan tidak mencakup arsip DoctorVisitReport, perlu memperjelas janji UI penghapusan seluruh wawasan |
| 18 | Community Moderation | Laporan/blok/review konten; keputusan sensitif ditinjau manusia | C `CommunitySafetyController.php`; S `CommunityModerationService.php`; M `community/presentation/community_safety.dart` | `/community/reports`, block/unblock, moderation queue/review | BELUM LENGKAP | Tes review manusia, larangan self-approve, scope moderator, revision/block lulus | Model unsafe confidence ≥0.75 langsung removed; regex juga langsung removed dan tidak masuk queue pending/flagged. Role global COMMUNITY_MODERATOR diblok middleware rute komunitas |
| 19 | Notification System | Reminder aktivitas, treatment, komunitas, Bantuan Cepat | S `NotificationService.php`; `backend/routes/console.php`; M core notifications | `/notifications`, read, `/devices`; FCM | BELUM LENGKAP | In-app storage, dedupe, reminder checkin/treatment, notifikasi komunitas tersedia dan sebagian dites | Tidak ada delivery/retry persisten; FCM device belum diverifikasi; scheduler hanya checkin/treatment, bukan jadwal aktivitas dukungan |
| 20 | Admin Content Management | Tambah/ubah/tinjau/terbitkan artikel, aktivitas, komunitas, sumber AI sesuai wewenang | C `AdminController.php`, `AdminWorkspaceController.php`, `AdminCommunityController.php`; `backend/resources/views/admin.blade.php` | `/admin`, `/admin/workspace/*`, activities/communities/knowledge ingest | BELUM LENGKAP | Panel web nyata tersedia; tes admin login, daftar akun aman dan create/deactivate community lulus | Artikel/sumber belum punya draft, daftar/edit terstruktur, review workflow/unpublish; role tambahan tidak didukung enum migration; moderator dashboard tidak memiliki aksi review |
| 21 | Autentikasi dan registrasi | Akun pengguna, pasien/pendamping, akses terautentikasi | M `auth/auth_screen.dart`, `core/api/api.dart`; C `AuthController.php` | register/login/me/logout; Sanctum | SELESAI DAN TERVERIFIKASI | Password min 12 + confirmation; role publik dibatasi; suite password/admin menguji login dan token, privacy menolak anonymous/admin registration | Tes komponen; belum login perangkat–MySQL; rate limit dinonaktifkan base TestCase sehingga tidak terverifikasi |
| 22 | Pemulihan kata sandi | Fungsi pendukung pengelolaan akun | M `auth/password_screen.dart`; C `PasswordController.php`; `backend/routes/web.php` | forgot/reset; email broker dan form web | TERKENDALA VERIFIKASI | Tes token single-use, expiry, wrong account, revoke session, mail failure lulus | Pengiriman email nyata dan membuka tautan dari mailbox belum diuji |
| 23 | Profil, onboarding, foto, hapus akun | Profil/konteks pasien dan pengelolaan akun | C `AuthController.php`, `ProfilePhotoController.php`; M settings/onboarding/treatment profile | PUT `/profile`, `/me/avatar`, DELETE `/me` | ADA TETAPI BELUM TERVERIFIKASI | Tes foto privat/encrypted/replace/delete dan penghapusan foto saat akun dihapus lulus; profil pasien tersimpan | Alur edit profil penuh dan cascade seluruh domain belum diuji lintas stack; PUT profile hanya pasien, caregiver tidak memiliki endpoint edit nama profil |
| 24 | Hak akses dan mode pengguna | Pasien, caregiver, administrator/moderator sesuai kewenangan | `backend/routes/api.php`, `routes/community.php`; migration users; router Flutter | role middleware, policies, admin modules | BELUM LENGKAP | PATIENT/CAREGIVER/ADMIN diuji; moderator keanggotaan komunitas tersedia | SUPER_ADMIN/CONTENT_ADMIN/COMMUNITY_MODERATOR di controller/rute tidak ada pada enum users; jalur moderator global tidak konsisten |
| 25 | Evaluasi AI kontekstual dan keselamatan | Bandingkan dengan/tanpa riwayat, relevansi, konsistensi, aktivitas kurasi, privasi dan batas medis | `ai-service/tests/test_engine.py`, `test_rag.py`, `test_community.py`; A `safety/service.py` | Tes komponen dan live probe audit | BELUM LENGKAP | Tes sintetis safety, ID/citation, consent tersedia; beberapa panggilan live berhasil | Belum bukti evaluasi berpasangan model nyata beserta rubrik/hasil kualitas, retrieval relevansi dan parafrasa medis Indonesia |
| 26 | Integrasi stack dan penyimpanan MySQL | Flutter–Laravel–MySQL–FastAPI–Qdrant berfungsi bersama | `docker-compose.yml`; migrations; `scripts/smoke_stack.py`; CI | HTTP stack dan DB relasional | TERKENDALA VERIFIKASI | Migration/adapter tersedia; tes audit memakai SQLite/in-memory | Tidak menjalankan migrasi atau smoke pada DB operasional; runtime layanan lokal tidak tersedia; tidak ada hasil MySQL/E2E baru pada audit ini |

## C. Audit khusus AI

### Jalur sebenarnya dan mode aktif

Flutter tidak memanggil provider langsung. `AiApplicationService`/`CaregiverController` menggunakan `AiClient::post`, mengirim internal service key ke FastAPI; `main.py` memeriksa key menggunakan `hmac.compare_digest`. FastAPI memakai `make_provider()` untuk memilih MockProvider, GroqProvider atau OpenAIProvider.

Pembacaan konfigurasi lokal melalui Settings menghasilkan mock=false, Groq dan `openai/gpt-oss-20b`. Keberadaan key hanya dilaporkan sebagai boolean. Ini adalah konfigurasi proses audit, **bukan identifikasi mode server yang sedang berjalan** karena health server lokal tidak terjangkau.

Tes live menggunakan FastAPI TestClient di proses lokal dan request sintetis, lalu SDK provider sungguhan. Tidak menggunakan database pasien. Hasil:

| Endpoint | Hasil audit | Makna dan batas |
|---|---|---|
| `/v1/ai/companion` | 200, metadata live, reply terisi | FastAPI→Groq benar-benar dapat merespons; belum pembuktian konteks Laravel atau persistensi |
| `/v1/ai/emotion/analyze` | 200, structured_llm_classification, fallback transformer_not_configured | Teks jurnal sintetis dianalisis model; bukan transformer lokal |
| `/v1/ai/caregiver-coach` | 200, permission_filtered_coach | Jalur model berjalan; konteks uji kosong, bukan bukti personalisasi pasien |
| `/v1/ai/recommendations` | 503 ai_unavailable | Kegagalan nyata pada probe; tidak dapat memastikan apakah structured output, safety check, timeout atau provider lain dari error publik |
| `/v1/ai/doctor-summary` | 503 ai_unavailable | Jalur live belum andal pada probe; agregat pun tidak dikembalikan karena narasi ditunggu |
| `/v1/rag/query` | 503 service_unavailable | Retrieval nyata belum terbukti. Dependensi embedding hilang dan Qdrant loopback tak terjangkau menjadi blocker terpisah |

Batch lima endpoint terakhir telah mencetak semua hasil di atas, tetapi proses kemudian melewati timeout keseluruhan 300 detik. Hasil HTTP dicatat sebagai observasi yang sudah tercetak, bukan klaim batch selesai dengan exit sukses. Tidak diulang untuk mengejar hasil yang menguntungkan.

### Konteks, izin, dan isolasi

`ContextService.php:14–119` membangun konteks dari check-in dalam periode, maksimum 200 gejala, maksimum 60 treatment, next treatment, sinyal emosi yang telah diizinkan dan aktivitas selesai. Semua query tersebut difilter user_id. Isi jurnal/chat mentah tidak dimasukkan ke konteks caregiver. Chat memakai history sesi milik pengguna dan delapan pesan terakhir.

Chat memerlukan AI_CHAT_CONTEXT. Analisis jurnal memerlukan AI_JOURNAL_ANALYSIS dan ai_analysis_allowed per entry. Pemeriksaan fingerprint/revision serta lock dilakukan sebelum menyimpan hasil agar hasil inference lama tidak disimpan sesudah pencabutan izin. Coach menyusun agregat sesuai permission dan memeriksa ulang hasil summary setelah AI kembali.

Insights, rekomendasi dan summary menggunakan HEALTH_DATA_PROCESSING melalui ContextService; tidak memerlukan AI_CHAT_CONTEXT. Ini bukan otomatis kebocoran: AI_CHAT_CONTEXT khusus chat, tetapi uraian consent harus memastikan pasien memahami bahwa health consent juga mengizinkan pengiriman skor ke layanan AI untuk fitur-fitur tersebut.

Tidak ditemukan bukti kebocoran jurnal lintas pengguna pada jalur yang diuji. Hal ini bukan jaminan seluruh endpoint/race bebas kelemahan. Query owner-scoped dan tests yang disebutkan merupakan bukti positif yang tersedia.

### Reflection dan rekomendasi

EmotionService menghasilkan kategori, skor, tema dan confidence. `AiController::journalReflection` tidak memiliki teks refleksi. Maka analisis emosi nyata tersedia, **AI Reflection sebagaimana tanggapan reflektif proposal belum lengkap**.

Rekomendasi menggunakan context dan hasil TrendService, memilih ID dari katalog yang diberikan, menolak ID asing/duplikat, dan memeriksa teks alasan dengan safety. Di Laravel hanya aktivitas active dipilih; flag medically_reviewed tidak menjadi syarat. MockProvider sekadar memilih dua aktivitas pertama dan memberi alasan demo; hasil tersebut tidak membuktikan personalisasi.

### RAG dan sumber

`rag/service.py` benar-benar memakai QdrantClient, sentence-transformers, chunking, cosine vector, filter reviewed + embedding_model, score threshold dan metadata sumber. Citation ID harus berasal dari hasil retrieval; citation palsu ditolak. Hasil kosong atau confidence rendah abstain. Qdrant tidak digunakan untuk menyimpan jurnal/chat pada jalur ini.

Tes `test_rag.py` memakai Qdrant `:memory:`, embedder vektor konstan `[1,0,0]`, dan CitedProvider stub, walaupun Settings mock=false. **Tes ini bukan keberhasilan semantic retrieval/model live.** `knowledge-base/` hanya berisi README; tidak ada korpus kurasi yang dikirim bersama folder tersebut. Ketersediaan korpus pada server lain tidak diperiksa dan tidak boleh diasumsikan kosong.

Ingest mengganti chunk berdasarkan source_id; delete kemudian upsert tidak atomik lintas sistem. Laravel menyimpan artikel JSON setelah ingest berhasil, tanpa transaksi lintas filesystem/Qdrant. Kegagalan salah satu sisi dapat membuat indeks dan artikel tidak sinkron. Reviewed_by berupa string input, bukan bukti review manusia independen yang terikat akun.

### Safety dan kegagalan

System prompt melarang diagnosis, dosis, perubahan terapi, klaim sembuh, dan instruksi dari dokumen/pesan tidak tepercaya. SafetyService memakai regex krisis/unsafe dan classifier LLM pada mode live. Unsafe output menjadi ProviderError/503. Krisis yang cocok regex mengembalikan arahan bantuan manusia. Belum ada bukti evaluasi klinis atau ketahanan terhadap seluruh parafrasa/injection.

Provider error dikembalikan FastAPI sebagai 503 dengan kode umum; AiClient Laravel juga mengubah koneksi/response gagal menjadi 503. Flutter memiliki pesan AI tidak tersedia. Tidak ada fallback diam-diam dari live ke mock di make_provider. Community moderation berbeda: ketika model gagal, regex lokal dapat auto-approve teks yang tidak cocok aturan. Ini harus dinilai sebagai fallback berbasis aturan, bukan pemeriksaan AI semantik yang berhasil.

OpenAI adapter menggunakan store=false; Groq adapter tidak memiliki argumen tersebut. Karena itu klaim README bahwa provider call memakai store=false tidak berlaku seragam. Kebijakan retensi provider tidak dapat disimpulkan dari kode.

## D. Masalah integrasi dan keamanan

### D1 — P0: Status Bantuan Cepat menyesatkan tentang delivery

Bukti: `SupportAlertController.php:25–29,43–59`; `NotificationService.php:28–63`; `quick_help_screen.dart:224–236`.

Recipient_count adalah jumlah baris penerima yang ditargetkan, bukan jumlah perangkat menerima. FCM tidak terkonfigurasi langsung return; error/token gagal ditelan; hasil HTTP selain 404 tidak menjadi status delivery. UI tetap mengatakan “Bantuan sudah dikirim”, “Pendampingmu sudah diberi tahu”, dan “pendamping menerima alert”. Proposal secara eksplisit menuntut pemisahan tercatat, pemberitahuan dikirim, dan bantuan dikonfirmasi. Dampaknya pasien dapat menunggu bantuan yang belum diketahui pendamping. ACKNOWLEDGED tersedia, tetapi tidak menyelesaikan klaim delivery sebelum acknowledgment.

### D2 — P1: Peran admin/moderator tidak konsisten

Migration `2026_10_07_000001_create_hopely_schema.php:13` hanya mengizinkan PATIENT/CAREGIVER/ADMIN. Semua lima migration yang ada tidak menambah enum role. `AdminWorkspaceController::ROLES` menambahkan SUPER_ADMIN/CONTENT_ADMIN/COMMUNITY_MODERATOR; `routes/community.php:10` hanya menerima PATIENT/CAREGIVER/ADMIN. MySQL schema yang dibuat dari migration tidak mendukung role tambahan tersebut. Moderator berbasis community membership pada role dasar berbeda dan memiliki tes lulus; jangan menyimpulkan semua moderasi tidak ada.

### D3 — P1: Jalur rekomendasi/ringkasan/RAG live gagal pada audit

HTTP 503 tercatat untuk tiga endpoint; belum ada bukti akar masalah spesifik provider rekomendasi/summary. RAG juga belum memiliki dependensi embedding lokal. Prioritasnya reproduksi terisolasi dan diagnosis tanpa menampilkan secret/payload pasien, bukan menganggap mock sebagai solusi selesai.

### D4 — P2: Moderasi sensitif dapat final otomatis

`CommunityModerationService.php:101–107,127–149` dapat langsung removed dari model/regex. Aturan termasuk frasa “diperkosa” atau “pelecehan seksual”, sehingga cerita sensitif korban dapat terhapus otomatis. Queue `CommunitySafetyController.php:111–123` memilih pending/flagged, bukan removed. Jalur sensitif ini belum menjamin peninjauan manusia sesuai proposal. Regex fallback juga mengizinkan teks yang tidak cocok aturan saat AI gagal.

### D5 — P2: Editorial dan kurasi belum lengkap

Panel admin ada, bukan placeholder. Namun knowledge form hanya ingest/publish, tidak menyediakan draft, review terikat akun, unpublish atau daftar dokumen administratif. Artikel lokal JSON terkait keberhasilan Qdrant; sumber dan artikel belum memiliki siklus pengelolaan lengkap. Aktivitas active dapat direkomendasikan meskipun medically_reviewed=false; belum ada workflow approval yang mengikat flag ini.

### D6 — P2: Reminder, push, dan persetujuan alert

Scheduler hanya treatment dan daily_checkin. Tidak ada reminder terjadwal aktivitas dukungan. Push tidak menyimpan delivery/failure atau retry persisten. PushService default FCM_ENABLED=false dan token refresh hanya mencoba register; tes perangkat diperlukan.

Manual SupportAlertController memeriksa accepted link + permission can_receive_support_alert tetapi tidak memeriksa global CAREGIVER_ALERT/HEALTH_DATA_PROCESSING; automated `NotificationService::supportAlert` memeriksa keduanya. Karena permintaan manual merupakan aksi eksplisit pengguna, ini tidak otomatis dianggap kebocoran; namun semantik pencabutan izin perlu diselaraskan dan dites agar pasien tidak menerima janji izin yang berbeda antarjalur.

### D7 — P2/P3: Pengelolaan profil dan data turunan

PUT profile hanya menerima pasien dan memperbarui PatientProfile.display_name, tidak User.name. Caregiver listing memakai User.name sehingga perubahan display_name pasien tidak tercermin pada nama di daftar caregiver. Tidak ada endpoint edit nama caregiver. `ConsentService` menghapus insight/rekomendasi/sinyal tetapi tidak arsip report; UI menjanjikan penghapusan wawasan turunan tersimpan tanpa menjelaskan pengecualian ini. Ini perlu klarifikasi perilaku, bukan mengasumsikan laporan wajib dihapus.

### D8 — Batas keamanan yang sudah diterapkan dan belum diuji

Sanctum, role middleware, health consent, owner Gate, enkripsi journal/chat/notes/report/device token, hash invitation, dan validasi input tersedia. Tes mendukung beberapa kontrol tersebut. Base TestCase menonaktifkan ThrottleRequests, sehingga rate limiting belum diuji. SQLite tidak membuktikan locking/concurrency dan enum MySQL. Token mobile tidak memiliki auto-expiration (diuji eksplisit oleh PasswordResetTest); logout dan reset password mencabut token sesuai jalurnya. Kebijakan sesi perlu dinilai berdasarkan kebutuhan operasional, bukan dinyatakan kebocoran tanpa bukti.

## E. Pengujian yang dijalankan dan batasnya

| Pengujian | Perintah/metode | Hasil | Batas |
|---|---|---|---|
| Proposal | Python zipfile + ElementTree, `word/document.xml`, seluruh paragraf | Teks lengkap terbaca | Tidak menilai desain/gambar mockup |
| Laravel | `php vendor/phpunit/phpunit/phpunit --do-not-cache-result --no-progress --colors=never` dengan APP_ENV=testing, DB_CONNECTION=sqlite, DB_DATABASE=:memory:, cache/session/mail array | Exit 0; 47 tests, 304 assertions | Bukan MySQL; Http/notification fake pada tes terkait; warning 503 moderation berasal skenario fallback |
| FastAPI | `.venv\Scripts\python.exe -B -m pytest -q -p no:cacheprovider tests` | 53 passed, 2.83s | conftest memaksa mock; stub/in-memory RAG |
| Flutter | `flutter test --no-pub --reporter expanded` | Exit 0; 54 passed | Fake API/widget; beberapa tes suite menghasilkan gambar review, tidak digunakan untuk audit desain |
| Flutter analyzer | `flutter analyze --no-pub` | Awal timeout 120s; rerun menghasilkan exit 1, empat info lint | Chat:55; record_history:38,44; stitch_v2_detail:228; bukan kegagalan fungsi yang terbukti |
| AI live | FastAPI TestClient, Settings lokal, input sintetis | Tabel hasil pada C | Tidak melalui server HTTP Laravel atau MySQL; batch terakhir timeout setelah hasil tercetak |
| Health lokal | GET 127.0.0.1:8000/up, :8001/health, :6333/healthz | URLError untuk ketiganya | Hanya alamat lokal yang diperiksa |
| Dependensi | Get-Command dan versi; importlib.find_spec | PHP 8.2.12, Python host 3.14.8, Flutter tersedia, Docker tidak di PATH; sentence_transformers venv tidak ada | Tidak menginstal/mengubah dependensi |

Tidak menjalankan db:seed, migrate, migrate:fresh, atau smoke_stack pada data operasional. Tes backend memakai database in-memory dan fixture sintetis. Tes dan alat dapat membuat artefak build/cache/log yang diabaikan Git; kode aplikasi tidak diedit.

## F. Prioritas perbaikan

1. **P0:** Pisahkan status tercatat/delivery/acknowledged Bantuan Cepat; tampilkan kegagalan yang benar dan arahan darurat. Jangan menyamakan target penerima dengan penerimaan pesan.
2. **P1:** Pulihkan rekomendasi, Doctor Summary, dan RAG live; verifikasi embedding/Qdrant/korpus; uji seluruh stack MySQL terisolasi.
3. **P1:** Selaraskan schema role, middleware, policy, dan dashboard admin/moderator.
4. **P2:** Lengkapi tanggapan AI Reflection; workflow review manusia sensitif; editorial artikel/sumber; kurasi aktivitas; reminder aktivitas; lifecycle push.
5. **P2:** Evaluasi AI dengan/tanpa konteks dan keselamatan model nyata; verifikasi PDF, email, serta perangkat. Lengkapi profil caregiver dan jelaskan kebijakan consent/arsip.
6. **P3:** Sinkronisasi nama profil lintas tampilan dan empat lint analyzer; dokumentasi lama yang menyebut admin panel/komunitas belum ada harus diperbarui setelah keputusan fungsional.

# DAFTAR FINAL FITUR YANG BELUM ADA ATAU BELUM SELESAI

Tidak ditemukan fitur utama yang sepenuhnya tidak mempunyai kode. Ada subfungsi yang belum ada dan fitur yang implementasinya belum memenuhi kebutuhan. Mode mock tersedia sebagai opsi pengujian, tetapi konfigurasi lokal AI bukan mock; tidak tepat melabeli seluruh aplikasi sebagai MOCK / PLACEHOLDER.

| No | Nama Fitur | Status | Apa yang Belum Ada | File/Komponen Terkait | Prioritas Perbaikan |
| -- | ---------- | ------ | ------------------ | --------------------- | ------------------- |
| 1 | Bantuan Cepat | BELUM LENGKAP | Status delivery/failure terpisah, klaim penerimaan yang akurat, arahan darurat pada panel | SupportAlertController; NotificationService; quick_help_screen.dart | P0 |
| 2 | Personalized Support Activities | BELUM LENGKAP | Keberhasilan jalur live (probe 503), pengendalian kurasi katalog yang konsisten | AiApplicationService::recommended; AIEngine.recommendations; SupportActivity | P1 (live), P2 (kurasi) |
| 3 | Doctor Visit Summary | BELUM LENGKAP | Jalur live berhasil (probe 503); penanganan kegagalan narasi agar fungsi ringkasan tetap jelas | AIEngine.summary; AiApplicationService::summary; summary_screen.dart | P1 |
| 4 | Trusted Knowledge berbasis RAG | BELUM LENGKAP | Runtime retrieval yang berhasil, dependency embedding lokal, pembuktian korpus kurasi dan sumber relevan | rag/service.py; knowledge-base; Qdrant | P1 |
| 5 | Hak akses admin/moderator | BELUM LENGKAP | Konsistensi role tambahan pada MySQL, rute dan aksi moderator global | users migration; routes/community.php; AdminWorkspaceController; admin.blade.php | P1 |
| 6 | AI Reflection | BELUM LENGKAP | Tanggapan reflektif berbasis jurnal, bukan hanya skor/tema | EmotionService; AiController::journalReflection; JournalAiInsight; layar reflection | P2 |
| 7 | Artikel Kesehatan | BELUM LENGKAP | Katalog kurasi operasional terverifikasi; publikasi/edit/review/unpublish yang tidak tergantung keberhasilan ingest AI semata | KnowledgeArticleController; AdminController::ingest; article_screen.dart | P2 |
| 8 | Admin Content Management | BELUM LENGKAP | Lifecycle editorial artikel/sumber, review terikat kewenangan/identitas dan pengelolaan dokumen terstruktur | admin.blade.php; AdminController; AdminWorkspaceController | P2 |
| 9 | Community Moderation | BELUM LENGKAP | Peninjauan manusia untuk keputusan sensitif yang kini langsung removed; alur role moderator konsisten | CommunityModerationService; CommunitySafetyController; routes/community.php | P2 |
| 10 | Notification System | BELUM LENGKAP | Delivery/failure/retry persisten; reminder aktivitas dukungan; pembuktian push perangkat | NotificationService; routes/console.php; PushService | P2; delivery Bantuan Cepat P0 |
| 11 | Pengelolaan profil caregiver dan konsistensi nama | BELUM LENGKAP (subfungsi) | Edit nama caregiver; sinkronisasi PatientProfile.display_name dengan nama yang ditampilkan ke caregiver | AuthController::profile; CaregiverController::patients; profil Flutter | P2/P3 |
| 12 | Evaluasi AI kontekstual dan keselamatan | BELUM LENGKAP | Hasil evaluasi model nyata dengan/tanpa konteks, rubrik relevansi/konsistensi, safety Indonesia dan sumber RAG | ai-service/tests; pipeline evaluasi AI | P2 |

## Fitur yang memiliki kode tetapi belum dapat diverifikasi secara memadai

Bagian ini dipisahkan dari gap implementasi di atas: belum diuji tidak otomatis berarti belum diimplementasikan.

| Fitur | Status audit | Verifikasi yang masih diperlukan |
|---|---|---|
| Daily Check-In | ADA TETAPI BELUM TERVERIFIKASI | CRUD lengkap melalui Flutter/backend nyata dan MySQL |
| Symptom Tracker | ADA TETAPI BELUM TERVERIFIKASI | Tambah/baca/ubah/hapus serta riwayat lintas stack |
| Treatment Journey | ADA TETAPI BELUM TERVERIFIKASI | CRUD utama dan alarm/reminder perangkat; tes scheduler saja belum cukup |
| Hopely AI Companion | ADA TETAPI BELUM TERVERIFIKASI | Integrasi Laravel→FastAPI live, persistensi MySQL, personalisasi riwayat berizin |
| Private Journal | ADA TETAPI BELUM TERVERIFIKASI | CRUD lengkap dan pemulihan error lewat perangkat |
| Emotional Insights | ADA TETAPI BELUM TERVERIFIKASI | Data sintetis multi-hari dari MySQL hingga grafik/ringkasan Flutter |
| Caregiver AI Coach | ADA TETAPI BELUM TERVERIFIKASI | Konteks pasien berizin sungguhan pada alur sintetis Laravel→AI; revoke saat inference |
| PDF Report Export | ADA TETAPI BELUM TERVERIFIKASI | Generate, simpan, buka kembali, cetak/preview dokumen pada perangkat |
| Pemulihan kata sandi | TERKENDALA VERIFIKASI | Email transport nyata, tautan mailbox dan reset pengguna |
| Profil/onboarding/hapus akun di luar foto | ADA TETAPI BELUM TERVERIFIKASI | Edit profil, persistensi dan cascade seluruh domain lintas stack |
| Integrasi stack dan MySQL | TERKENDALA VERIFIKASI | Lingkungan sintetis terisolasi Laravel–MySQL–FastAPI–Qdrant dan perangkat Flutter |
| FCM dan notifikasi perangkat | TERKENDALA VERIFIKASI (bagian Notification System) | Kredensial/build/perangkat, delivery dan token refresh nyata |

Support Circle, Care Circle, Privacy & Consent, dan autentikasi memiliki bukti tes alur utama komponen sebagaimana matriks; status tersebut tetap tidak menyatakan seluruh aplikasi sudah lolos uji end-to-end atau validasi klinis.
