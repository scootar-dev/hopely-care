import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';
import '../../core/theme/theme.dart';

class PasswordScreen extends ConsumerStatefulWidget {
  const PasswordScreen({super.key});
  @override
  ConsumerState<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends ConsumerState<PasswordScreen> {
  final email = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false, sent = false;
  Object? error;
  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(apiProvider).post('/auth/forgot-password', {
        'email': email.text.trim(),
      });
      if (mounted) setState(() => sent = true);
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/login'),
      title: const Text('Pemulihan Akun'),
    ),
    body: PageBody(
      children: [
        const CareCard(
          color: skySoft,
          child: Row(
            children: [
              Icon(Icons.lock_reset, color: hopelyBlue, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'RUANG TEDUH & AMAN\nAkses kembali ruang pribadimu.',
                ),
              ),
            ],
          ),
        ),
        const Heading(
          'Atur Ulang Kata Sandi',
          'Masukkan alamat email yang terdaftar untuk menerima tautan pemulihan.',
        ),
        if (sent)
          const CareCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  color: hopelyBlue,
                  size: 36,
                ),
                SizedBox(height: 16),
                Text('Periksa kotak masuk dan spam'),
                SizedBox(height: 8),
                Text(
                  'Jika email terdaftar, instruksi pemulihan akan dikirim. Buka tautannya untuk membuat kata sandi baru.',
                ),
              ],
            ),
          )
        else
          Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alamat Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: email,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'nama@email.com',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Isi email yang sesuai'
                      : null,
                ),
                const SizedBox(height: 24),
                if (error != null) ErrorNotice(error!),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(busy ? 'Mengirim…' : 'Kirim Tautan'),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        const PrivacyNote(
          'Tautan pemulihan berlaku 15 menit dan hanya dapat digunakan sekali.',
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('← Kembali ke Masuk'),
        ),
      ],
    ),
  );
}
