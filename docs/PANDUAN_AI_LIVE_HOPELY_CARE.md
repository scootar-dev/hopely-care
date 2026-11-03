# Panduan AI live Hopely Care

Konfigurasi aktual berada di `ai-service/app/core/config.py`, pemilihan provider di `app/llm/provider.py`. Default provider konfigurasi adalah Groq. Jangan mengganti provider tanpa persetujuan.

1. Gunakan virtualenv proyek dan dependensi `ai-service/pyproject.toml`. Pada Windows jalankan dari `ai-service`: `.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8001`.
2. Konfigurasi privat: INTERNAL_SERVICE_KEY minimal 32 karakter, MOCK_AI_MODE=false, LLM_PROVIDER=groq, GROQ_API_KEY (atau LLM_API_KEY sesuai konfigurasi), LLM_MODEL dengan model yang tersedia bagi akun resmi. APP_ENV=production menolak mock.
3. Settings membaca `.env` dan `../.env`; periksa precedence agar file root tidak tanpa sengaja mengganti nilai layanan. Jangan mencetak nilai key untuk pemeriksaan.
4. Laravel memerlukan AI_SERVICE_URL dan INTERNAL_SERVICE_KEY yang cocok. Browser/Flutter tidak boleh memperoleh internal key.
5. Gunakan akun pasien dan caregiver sintetis. Hubungkan, berikan consent dan izin tertentu, lalu ajukan pertanyaan nonklinis melalui Panduan Pendamping.
6. Periksa metadata.mode=`live` dan respons provider nyata. Metadata saja tidak menggantikan bukti request berhasil. Fixture tes dan mock bukan live.
7. Cabut izin; pastikan summary/Coach ditolak atau konteks berkurang dan respons lama dibersihkan. Uji pasien kedua agar konteks tidak tertukar.

Coach menerima agregat berizin dari Laravel, bukan raw jurnal/chat. Jalur Coach tidak sama dengan Trusted Knowledge RAG; jangan mengklaim Coach mengakses Qdrant bila tidak menjalankan jalur RAG. Kegagalan provider harus tampil sebagai error, bukan jawaban sukses buatan.

Uji unit yang aman: `.\.venv\Scripts\python.exe -m pytest tests/test_engine.py tests/test_functional_completion.py -q -p no:cacheprovider`. Hasil ini bukan verifikasi model live.

Jangan bagikan GROQ_API_KEY, LLM_API_KEY, INTERNAL_SERVICE_KEY, bearer token akun, atau data kesehatan nyata. Credential provider resmi dan akses layanan merupakan tanggung jawab pengelola; jangan membeli layanan atau mengganti provider sebagai jalan pintas.
