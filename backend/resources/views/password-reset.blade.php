<!doctype html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="referrer" content="no-referrer"><title>Atur ulang kata sandi · Hopely Care</title>
<style>body{font:16px/1.5 system-ui,sans-serif;color:#0b1c30;background:#f8f9ff;margin:0;padding:24px}main{max-width:420px;margin:8vh auto;background:white;border-radius:24px;padding:28px}h1{font-size:24px}label{display:block;margin:16px 0 6px}input,button{box-sizing:border-box;font:inherit;padding:14px;border-radius:12px;width:100%}input{border:1px solid #d3e4fe}button{background:#004ac6;color:white;border:0;margin-top:24px;cursor:pointer}.error{color:#a11}small{color:#526079}</style></head><body><main><small>HOPELY CARE</small>
@if($completed ?? false)
<h1>Kata sandi diperbarui</h1><p>Kembali ke aplikasi dan masuk menggunakan kata sandi barumu.</p>
@else
<h1>Atur ulang kata sandi</h1><p>Buat kata sandi baru untuk ruang pribadimu.</p>
@if($errors->any())<p class="error" role="alert">{{ $errors->first() }}</p>@endif
<form method="post" action="{{ route('password.update') }}">@csrf
<input type="hidden" name="token" value="{{ $token }}">
<label for="email">Alamat email</label><input id="email" name="email" type="email" required autocomplete="email" value="{{ old('email', $email) }}">
<label for="password">Kata sandi baru</label><input id="password" name="password" type="password" required minlength="12" autocomplete="new-password"><small>Minimal 12 karakter.</small>
<label for="confirmation">Konfirmasi kata sandi</label><input id="confirmation" name="password_confirmation" type="password" required minlength="12" autocomplete="new-password">
<button type="submit">Simpan kata sandi</button></form>
@endif
</main></body></html>
