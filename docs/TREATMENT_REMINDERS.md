# Pengingat perjalanan

APK menjadwalkan notifikasi lokal berdasarkan waktu UTC dari jadwal pasien dan menampilkannya pada waktu yang sesuai di HP. Tidak membutuhkan Firebase. Pengguna mengizinkan notifikasi saat menyimpan jadwal atau melalui Perjalanan / Pengaturan Notifikasi. Pada Android, izinkan alarm tepat waktu jika ingin pengingat sesuai menit jadwal; tanpa izin itu Android dapat menundanya. Force-stop, pembatasan baterai, dan izin OS dapat memengaruhi pengiriman.

Jadwal disinkronkan saat masuk, aplikasi kembali aktif, dan setelah perubahan jadwal. Jadwal yang dibatalkan, selesai, atau sudah lewat tidak dijadwalkan. Keluar akun atau mencabut persetujuan pemrosesan data kesehatan membatalkan pengingat lokal. Perubahan dari perangkat lain baru tersinkron saat aplikasi kembali aktif dan memiliki koneksi. Maksimal 60 jadwal terdekat disimpan di perangkat. Android memulihkan jadwal setelah reboot. Isi notifikasi tidak memuat judul, lokasi, atau catatan medis; ketuk notifikasi untuk membuka detail setelah autentikasi.

Backend juga membuat notifikasi dalam aplikasi: satu pengingat dalam 24 jam sebelum jadwal dan satu ketika waktunya tiba. Pemrosesan per menit menangkap jadwal yang terlewat hingga 24 jam, dengan deduplikasi. Jadwal selesai/dibatalkan dan akun tanpa persetujuan tidak diproses. Firebase opsional masih diperlukan untuk push backend ke perangkat yang didaftarkan melalui layanan push.

## Server systemd

Mengaktifkan ulang API saja tidak menjalankan scheduler. Jalankan Laravel scheduler sekali setiap menit melalui cron, atau gunakan service berikut (sesuaikan direktori dan pengguna server):

```ini
# /etc/systemd/system/hopely-scheduler.service
[Unit]
Description=Hopely Care Laravel scheduler
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/hopely-care/backend
ExecStart=/usr/bin/php artisan schedule:work
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now hopely-scheduler
sudo systemctl status hopely-scheduler
sudo journalctl -u hopely-scheduler -n 50 --no-pager
```

Setelah memperbarui kode backend, restart service scheduler juga. Jangan menjalankan cron dan service scheduler bersamaan. Periksa `php artisan schedule:list` dan uji `php artisan hopely:reminders` dari direktori backend.

## Verifikasi perangkat

1. Instal APK baru, masuk sebagai pasien, dan izinkan notifikasi serta alarm tepat waktu.
2. Buat jadwal 3-5 menit dari sekarang; tutup aplikasi tanpa force-stop. Notifikasi harus muncul saat jadwal tiba dan membuka detail saat diketuk.
3. Ubah jam jadwal, lalu ulangi; jam lama tidak boleh memunculkan pengingat.
4. Batalkan jadwal atau keluar akun sebelum waktu tiba; notifikasi lama tidak boleh muncul.
5. Pada iOS, uji izin dan notifikasi dengan build iOS tersendiri; build APK tidak memvalidasi iOS.
