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
  bool busy = false, obscured = true, remember = true;
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
      await ref.read(sessionProvider).setAuth(data as Json, remember: remember);
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
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'PATIENT',
              label: Text('Pasien'),
              icon: Icon(Icons.favorite_outline),
            ),
            ButtonSegment(
              value: 'CAREGIVER',
              label: Text('Pendamping'),
              icon: Icon(Icons.volunteer_activism_outlined),
            ),
          ],
          selected: {role},
          onSelectionChanged: busy
              ? null
              : (v) => setState(() => role = v.first),
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
      Row(
        children: [
          const Expanded(
            child: Text('Kata Sandi', style: TextStyle(color: ink)),
          ),
          if (!widget.register)
            TextButton(
              onPressed: busy ? null : () => context.push('/forgot-password'),
              child: const Text('Lupa kata sandi?'),
            ),
        ],
      ),
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
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Ingat saya', style: TextStyle(fontSize: 13)),
          value: remember,
          onChanged: busy ? null : (v) => setState(() => remember = v ?? false),
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
            const CareCard(
              color: skySoft,
              padding: 16,
              child: Row(
                children: [
                  HopelyMark(),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hopely Care\nRuang teduh bagi pasien & pendamping',
                    ),
                  ),
                ],
              ),
            ),
            const Heading(
              'Daftar Akun Baru',
              'Mulai langkah awal di ruang yang aman.',
            ),
          ] else ...[
            const Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: lavender,
                child: Icon(
                  Icons.volunteer_activism,
                  color: hopelyBlue,
                  size: 30,
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
        const Heading(
          'Kamu menggunakan Hopely sebagai?',
          'Pilih peran untuk menyesuaikan pengalaman pendampinganmu.',
        ),
        const CareCard(
          color: skySoft,
          child: Row(
            children: [
              HopelyMark(),
              SizedBox(width: 12),
              Expanded(child: Text('Ruang tenang untuk melangkah bersama.')),
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
            'Saya mendampingi keluarga atau kerabat.',
            Icons.volunteer_activism,
          ),
        ])
          CareCard(
            color: role == item.$1 ? skySoft : Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => role = item.$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: lavender,
                      child: Icon(item.$4, color: hopelyBlue),
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
                          const SizedBox(height: 8),
                          Text(item.$3),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      role == item.$1
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: hopelyBlue,
                    ),
                  ],
                ),
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
