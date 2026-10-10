# Hopely Care — Flutter

Jalankan Laravel dan database terlebih dahulu. Panduan backend, akun demo, AI mock/live, serta penanganan login ada di [README proyek](../README.md).

Untuk Android Emulator, dari folder ini:

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Chrome pada komputer backend memakai `http://127.0.0.1:8000/api`. HP fisik memerlukan endpoint yang dapat dijangkau HP; untuk Android USB, gunakan `adb reverse tcp:8000 tcp:8000` dan URL `http://127.0.0.1:8000/api` pada build debug.

Login menggunakan akun yang terdaftar di Hopely Care. Menjalankan Flutter tidak otomatis membuat akun atau menyalakan backend. Hentikan dan jalankan kembali Flutter setelah mengubah alamat API.
