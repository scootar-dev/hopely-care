import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/stitch.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.register = false,
    this.initialRole = 'PATIENT',
  });
  final bool register;
  final String initialRole;
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  final form = GlobalKey<FormState>();
  String role = 'PATIENT';
  bool busy = false, obscured = true;
  Object? error;
  @override
  void initState() {
    super.initState();
    role = widget.initialRole;
  }

  @override
  void dispose() {
    for (final c in [name, email, password, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await ref.read(apiProvider).post(
        widget.register ? '/auth/register' : '/auth/login',
        {
          'email': email.text.trim(),
          'password': password.text,
          if (widget.register) ...{
            'name': name.text.trim(),
            'password_confirmation': confirm.text,
            'role': role,
          },
        },
      );
      // The mobile session is persisted and remains valid until explicit revocation.
      await ref.read(sessionProvider).setAuth(data as Json);
      if (mounted) {
        context.go(
          ref.read(sessionProvider).caregiver ? '/caregiver' : '/home',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e);
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      if (widget.register) ...[
        const Text('Saya mendaftar sebagai:'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final option in const {
              'PATIENT': ('Pasien', Icons.favorite),
              'CAREGIVER': ('Pendamping', Icons.volunteer_activism),
            }.entries)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: option.key == 'PATIENT' ? 6 : 0,
                    left: option.key == 'CAREGIVER' ? 6 : 0,
                  ),
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: role == option.key
                          ? hopelyBlue
                          : skySoft,
                      foregroundColor: role == option.key ? Colors.white : ink,
                    ),
                    onPressed: busy
                        ? null
                        : () => setState(() => role = option.key),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(option.value.$2, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            option.value.$1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _label('Nama Lengkap'),
        TextFormField(
          controller: name,
          enabled: !busy,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(
            hintText: 'Nama lengkapmu',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Isi nama lengkap' : null,
        ),
        const SizedBox(height: 18),
      ],
      _label('Alamat Email'),
      TextFormField(
        controller: email,
        enabled: !busy,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(
          hintText: 'nama@email.com',
          prefixIcon: Icon(Icons.mail_outline),
        ),
        validator: (v) =>
            v == null || !v.contains('@') ? 'Isi email yang sesuai' : null,
      ),
      const SizedBox(height: 18),
      const Text('Kata Sandi', style: TextStyle(color: ink)),
      const SizedBox(height: 6),
      TextFormField(
        controller: password,
        enabled: !busy,
        obscureText: obscured,
        autofillHints: [
          widget.register ? AutofillHints.newPassword : AutofillHints.password,
        ],
        decoration: InputDecoration(
          hintText: widget.register ? 'Minimal 12 karakter' : 'Kata sandimu',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            tooltip: obscured
                ? 'Tampilkan kata sandi'
                : 'Sembunyikan kata sandi',
            onPressed: () => setState(() => obscured = !obscured),
            icon: Icon(
              obscured
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
        validator: (v) => v == null || v.length < (widget.register ? 12 : 1)
            ? (widget.register
                  ? 'Gunakan minimal 12 karakter'
                  : 'Isi kata sandi')
            : null,
      ),
      if (!widget.register)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: busy ? null : () => context.push('/forgot-password'),
            child: const Text('Lupa kata sandi?'),
          ),
        ),
      if (widget.register) ...[
        const SizedBox(height: 18),
        _label('Konfirmasi Kata Sandi'),
        TextFormField(
          controller: confirm,
          enabled: !busy,
          obscureText: obscured,
          autofillHints: const [AutofillHints.newPassword],
          decoration: const InputDecoration(
            hintText: 'Ulangi kata sandi',
            prefixIcon: Icon(Icons.verified_user_outlined),
          ),
          validator: (v) => v != password.text ? 'Kata sandi belum sama' : null,
        ),
      ] else
        const PrivacyNote(
          'Sesi login tersimpan aman di perangkat dan tetap aktif sampai kamu keluar, mengganti kata sandi, atau mencabut akses akun.',
        ),
      const SizedBox(height: 18),
      if (error != null) ErrorNotice(error!),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : submit,
          child: Text(
            busy
                ? 'Sebentar…'
                : widget.register
                ? 'Daftar  →'
                : 'Masuk  →',
          ),
        ),
      ),
      const SizedBox(height: 10),
      Center(
        child: TextButton(
          onPressed: busy
              ? null
              : () => context.go(widget.register ? '/login' : '/role'),
          child: Text(
            widget.register
                ? 'Sudah memiliki akun? Masuk'
                : 'Belum punya akun? Daftar',
          ),
        ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: const BackHomeButton(fallback: '/welcome'),
        title: Text(widget.register ? 'Daftar Akun' : 'Masuk'),
      ),
      body: PageBody(
        children: [
          if (widget.register) ...[
            CareCard(
              color: skySoft,
              padding: 16,
              radius: 16,
              child: const Row(
                children: [
                  HopelyMark(),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hopely Care Sanctuary\nRuang teduh bagi pejuang & pendamping',
                    ),
                  ),
                ],
              ),
            ),
            const Heading(
              'Daftar Akun Baru',
              'Mulai langkah awal ruang aman dan terpercaya.',
            ),
          ] else ...[
            const Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: primaryFixed,
                child: Icon(
                  Icons.volunteer_activism,
                  color: hopelyBlue,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Masuk ke Hopely Care',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Lanjutkan perjalanan pemulihan dan pendampinganmu.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
          AutofillGroup(
            child: Form(
              key: form,
              child: widget.register
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: fields,
                    )
                  : CareCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: fields,
                      ),
                    ),
            ),
          ),
          const PrivacyNote(
            'Kamu mengatur izin penggunaan data. Jurnal dan percakapan AI tetap pribadi.',
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: ink)),
  );
}

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String role = 'patient';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/welcome'),
      title: const Text('Pilih Peran'),
    ),
    body: PageBody(
      children: [
        const Text(
          'Langkah 1 dari 3',
          style: TextStyle(
            fontSize: 12,
            color: hopelyBlue,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        const Heading(
          'Kamu menggunakan Hopely sebagai?',
          'Pilih peran untuk menyesuaikan pengalaman pendampinganmu.',
        ),
        CareCard(
          color: skySoft,
          child: Row(
            children: [
              const HopelyMark(),
              const SizedBox(width: 12),
              const Expanded(child: Text('Ruang Tenang & Aman')),
            ],
          ),
        ),
        for (final item in const [
          (
            'patient',
            'Pasien',
            'Saya sedang menjalani masa perawatan atau pemulihan.',
            Icons.favorite,
          ),
          (
            'caregiver',
            'Pendamping',
            'Saya mendampingi keluarga atau kerabat yang sedang berjuang.',
            Icons.volunteer_activism,
          ),
        ])
          CareCard(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => role = item.$1),
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconWell(
                        item.$4,
                        size: 56,
                        radius: 16,
                        background: role == item.$1 ? primaryFixed : skySoft,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(item.$3),
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: role == item.$1
                          ? hopelyBlueDark
                          : surfaceHigh,
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: role == item.$1
                            ? Colors.white
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.go('/register?role=$role'),
          child: const Text('Lanjutkan  →'),
        ),
      ],
    ),
  );
}
