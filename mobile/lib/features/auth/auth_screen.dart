import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/theme/theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: PageBody(
        children: [
          const SizedBox(height: 64),
          const CircleAvatar(
            radius: 44,
            backgroundColor: mint,
            child: Icon(Icons.spa_outlined, size: 44, color: forest),
          ),
          const SizedBox(height: 32),
          const Heading(
            'Kamu tidak harus\nmelewati ini sendiri.',
            'Hopely Care menemani kamu mencatat perasaan, memahami perubahan, dan menyiapkan percakapan dengan tim perawatan.',
          ),
          const CareCard(
            child: Text(
              'Catatanmu tetap pribadi. Kamu yang memilih kapan AI boleh membantu dan apa yang boleh dilihat pendamping.',
            ),
          ),
          FilledButton(
            onPressed: () => context.go('/role'),
            child: const Text('Mulai perjalanan'),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sudah punya akun? Masuk'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pendamping wellbeing, bukan pengganti dokter atau psikolog.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

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
  bool busy = false;
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hopely Care')),
    body: PageBody(
      children: [
        Heading(
          widget.register ? 'Mari berkenalan' : 'Selamat datang kembali',
          'Ruang tenang untuk perjalananmu.',
        ),
        Form(
          key: form,
          child: CareCard(
            child: Column(
              children: [
                if (widget.register) ...[
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'PATIENT', label: Text('Pasien')),
                      ButtonSegment(
                        value: 'CAREGIVER',
                        label: Text('Pendamping'),
                      ),
                    ],
                    selected: {role},
                    onSelectionChanged: (v) => setState(() => role = v.first),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Nama panggilan',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Isi nama panggilan'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Isi email yang sesuai'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Kata sandi'),
                  validator: (v) =>
                      v == null || v.length < (widget.register ? 12 : 1)
                      ? 'Gunakan minimal 12 karakter'
                      : null,
                ),
                if (widget.register) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Ulangi kata sandi',
                    ),
                    validator: (v) =>
                        v != password.text ? 'Kata sandi belum sama' : null,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (error != null) ErrorNotice(error!),
        FilledButton(
          onPressed: busy ? null : submit,
          child: Text(
            busy
                ? 'Sebentar…'
                : widget.register
                ? 'Buat akun'
                : 'Masuk',
          ),
        ),
        TextButton(
          onPressed: () => context.go(widget.register ? '/login' : '/register'),
          child: Text(widget.register ? 'Sudah punya akun' : 'Buat akun baru'),
        ),
      ],
    ),
  );
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mari Berkenalan')),
    body: PageBody(
      children: [
        const Heading(
          'Bagaimana Hopely dapat menemanimu?',
          'Pilih peran untuk menyiapkan ruang yang sesuai.',
        ),
        CareCard(
          child: Column(
            children: [
              const Icon(Icons.favorite_outline, color: forest, size: 40),
              const SizedBox(height: 16),
              const Text('Saya menjalani perawatan kanker'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/register?role=patient'),
                child: const Text('Lanjut sebagai pasien'),
              ),
            ],
          ),
        ),
        CareCard(
          child: Column(
            children: [
              const Icon(Icons.people_outline, color: forest, size: 40),
              const SizedBox(height: 16),
              const Text('Saya mendampingi orang terdekat'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/register?role=caregiver'),
                child: const Text('Lanjut sebagai pendamping'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
