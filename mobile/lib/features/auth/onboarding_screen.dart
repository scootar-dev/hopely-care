import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: PageBody(
        children: [
          SizedBox(height: 48),
          Center(
            child: SoftLabel('Ruang untuk didengarkan', icon: Icons.circle),
          ),
          CareHero(compact: true),
          Text(
            'Hopely Care',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 38,
              color: hopelyBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Text('Temani setiap langkahmu.', textAlign: TextAlign.center),
          SizedBox(height: 32),
          PrivacyNote('Hadir dengan kelembutan untuk jiwa dan ragamu.'),
          SizedBox(height: 32),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 28),
          Text(
            'PENDAMPING PSIKO-ONKOLOGI DIGITAL',
            textAlign: TextAlign.center,
            style: TextStyle(color: hopelyBlue, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: PageBody(
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              SoftLabel('Hopely Care • Sahabat perjalanan', icon: Icons.circle),
              SoftLabel('Privasi dalam kendalimu', icon: Icons.shield_outlined),
            ],
          ),
          const CareHero(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Benefit(Icons.volunteer_activism_outlined, 'Dukungan'),
              _Benefit(Icons.monitor_heart_outlined, 'Pencatatan'),
              _Benefit(Icons.people_outline, 'Terhubung'),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'RUANG RAMAH & PENUH HARAPAN',
            textAlign: TextAlign.center,
            style: TextStyle(color: hopelyBlue, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          Text(
            'Kamu tidak harus melewati semuanya sendirian.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const Text(
            'Hopely Care menemani perjalanan emosimu, mencatat kondisi fisik, dan membantu kamu terhubung dengan orang terkasih.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          const CareCard(
            color: skySoft,
            padding: 16,
            child: Text(
              '“Satu langkah kecil hari ini tetap berarti.”',
              textAlign: TextAlign.center,
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.go('/onboarding'),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Mulai Sekarang'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sudah punya akun? Masuk'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pendamping wellbeing, bukan pengganti dokter atau psikolog.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: hopelyBlue),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  static const pages = [
    (
      'Kenali keadaanmu',
      'Catat suasana hati, kecemasan, dan kondisi fisik harian dengan lembut. Tidak ada jawaban yang salah.',
      Icons.favorite_outline,
    ),
    (
      'Ada ruang untuk ceritamu',
      'Tulis jurnal pribadi atau berbicara dengan Hopely AI. Kamu memilih kapan AI boleh menggunakan konteksmu.',
      Icons.auto_awesome_outlined,
    ),
    (
      'Melangkah bersama',
      'Undang orang yang kamu percaya dan tentukan ringkasan yang boleh mereka lihat. Jurnal dan chat tetap pribadi.',
      Icons.people_outline,
    ),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/welcome'),
      title: const Text(
        'HOPELY CARE',
        style: TextStyle(fontSize: 15, color: hopelyBlue),
      ),
      actions: [
        TextButton(
          onPressed: () => context.go('/role'),
          child: const Text('Lewati'),
        ),
      ],
    ),
    body: SafeArea(
      child: PageBody(
        children: [
          CareCard(
            color: skySoft,
            child: Column(
              children: [
                SoftLabel('Langkah ${step + 1}', icon: pages[step].$3),
                const CareHero(compact: true),
                if (step == 0)
                  const CareCard(
                    padding: 14,
                    child: Column(
                      children: [
                        Text('Bagaimana keadaanmu hari ini?'),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Icon(
                              Icons.sentiment_very_dissatisfied,
                              color: hopelyBlue,
                            ),
                            Icon(
                              Icons.sentiment_dissatisfied,
                              color: hopelyBlue,
                            ),
                            Icon(Icons.sentiment_neutral, color: hopelyBlue),
                            Icon(Icons.sentiment_satisfied, color: hopelyBlue),
                            Icon(
                              Icons.sentiment_very_satisfied,
                              color: hopelyBlue,
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Skala 1–5 • contoh tampilan',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                if (step > 0)
                  PrivacyNote(
                    step == 1
                        ? 'Izin AI dapat diubah kapan saja.'
                        : 'Berbagi sesuai kenyamananmu.',
                  ),
              ],
            ),
          ),
          Heading(pages[step].$1, pages[step].$2),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Container(
                width: i == step ? 30 : 9,
                height: 9,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: i == step ? hopelyBlue : pillBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () =>
                step < 2 ? setState(() => step++) : context.go('/role'),
            icon: const Icon(Icons.arrow_forward),
            label: Text(step == 2 ? 'Mulai Perjalanan' : 'Lanjutkan'),
          ),
          const SizedBox(height: 12),
          Text('Langkah ${step + 1} dari 3', textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
