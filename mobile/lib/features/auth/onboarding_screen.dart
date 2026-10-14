import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';
import '../../core/widgets/reference_art.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: pillBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x160B1C30),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const HopelyMark(size: 64),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Hopely Care',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text('Temani setiap langkahmu.'),
                    const SizedBox(height: 24),
                    Semantics(
                      label: 'Memuat ruang pribadimu',
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    const Spacer(flex: 3),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user, size: 14, color: hopelyBlue),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Pendamping wellbeing dalam kendalimu',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
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
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HopelyMark(size: 32),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'HopelyCare',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SoftLabel('Ruang Teduh', icon: Icons.circle),
            ],
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: ReferenceArt(
              asset: 'welcome.png',
              imageSize: Size(390, 884),
              crop: Rect.fromLTWH(25, 65, 340, 339),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Kamu tidak harus melewati semuanya sendirian.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ruang aman dan pendamping penuh empati untuk menemani setiap fase pemulihanmu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.65),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/onboarding'),
            child: const Text('Mulai Sekarang  →'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => context.go('/login'),
            child: const Text('Masuk'),
          ),
        ],
      ),
    ),
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
      'Catat kondisi harianmu dengan mudah.',
      'checkin.png',
      Size(390, 884),
      Rect.fromLTWH(33, 73, 324, 323),
    ),
    (
      'Ditemani Hopely',
      'Ceritakan apa yang kamu rasakan.',
      'companion.png',
      Size(390, 880),
      Rect.fromLTWH(30, 85, 331, 330),
    ),
    (
      'Lebih dekat dengan dukungan',
      'Terhubung dengan keluarga dan komunitas.',
      'circle.png',
      Size(390, 884),
      Rect.fromLTWH(52, 81, 285, 285),
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final page = pages[step];
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          children: [
            Row(
              children: [
                if (step == 0)
                  const Expanded(
                    child: Row(
                      children: [
                        HopelyMark(size: 28),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Hopely Care',
                            style: TextStyle(
                              color: hopelyBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Langkah sebelumnya',
                        onPressed: () => setState(() => step--),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => context.go('/role'),
                  child: const Text('Lewati'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140B1C30),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: ReferenceArt(
                    key: ValueKey(step),
                    asset: page.$3,
                    imageSize: page.$4,
                    crop: page.$5,
                    radius: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              page.$1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              page.$2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 30),
            Semantics(
              label: 'Langkah ${step + 1} dari 3',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Container(
                    width: i == step ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: i == step ? hopelyBlueDark : pillBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  step < 2 ? setState(() => step++) : context.go('/role'),
              child: Text(step == 2 ? 'Mulai Sekarang  →' : 'Lanjut  →'),
            ),
          ],
        ),
      ),
    );
  }
}
