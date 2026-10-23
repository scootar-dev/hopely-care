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
    backgroundColor: canvas,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 144,
                          height: 144,
                          decoration: BoxDecoration(
                            color: surfaceHighest.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 112,
                          height: 112,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: hopelyCardShadow,
                          ),
                          child: const Center(child: HopelyMark(size: 64)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Hopely Care',
                      style: TextStyle(
                        fontSize: 24,
                        height: 32 / 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.36,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Temani setiap langkahmu.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 22 / 15,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      label: 'Memuat ruang pribadimu',
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PulseDot(opacity: 0.4),
                          SizedBox(width: 6),
                          _PulseDot(opacity: 0.7),
                          SizedBox(width: 6),
                          _PulseDot(opacity: 0.4),
                        ],
                      ),
                    ),
                    const Spacer(flex: 3),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user, size: 15, color: hopelyBlue),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Pendamping Psiko-Onkologi Terpercaya',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.opacity});
  final double opacity;
  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(
      color: hopelyBlue.withValues(alpha: opacity),
      shape: BoxShape.circle,
    ),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    body: SafeArea(
      child: PageBody(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const HopelyMark(size: 32),
              const SizedBox(width: 8),
              const Text(
                'Hopely',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                'Care',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: hopelyBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: skySoft,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Color(0xFF3755C3)),
                    SizedBox(width: 6),
                    Text(
                      'Ruang Teduh',
                      style: TextStyle(fontSize: 12, color: mutedInk),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const ReferenceArt(
            asset: 'welcome.png',
            imageSize: Size(390, 844),
            crop: Rect.fromLTWH(24, 63, 342, 342),
            radius: 28,
          ),
          Text(
            'Kamu tidak harus melewati semuanya sendirian.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ruang aman dan pendamping penuh empati untuk mendampingi setiap fase pemulihanmu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.5, color: mutedInk),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/onboarding'),
            icon: const Icon(Icons.arrow_forward, size: 20),
            label: const Text('Mulai Sekarang'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: skySoft,
                foregroundColor: hopelyBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => context.go('/login'),
              child: const Text('Masuk'),
            ),
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
      Rect.fromLTWH(25, 83, 340, 338),
      'Ruang Tenang',
    ),
    (
      'Ditemani Hopely',
      'Ceritakan apa yang kamu rasakan.',
      'companion.png',
      Rect.fromLTWH(27, 83, 337, 338),
      'Ruang Aman Anda',
    ),
    (
      'Lebih dekat dengan dukungan',
      'Terhubung dengan keluarga dan komunitas.',
      'circle.png',
      Rect.fromLTWH(39, 69, 312, 298),
      'Langkah Terakhir',
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final page = pages[step];
    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: PageBody(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  if (step == 0)
                    const Expanded(
                      child: Row(
                        children: [
                          HopelyMark(size: 28),
                          SizedBox(width: 6),
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
                    child: const Text(
                      'Lewati',
                      style: TextStyle(color: tertiaryInk),
                    ),
                  ),
                ],
              ),
            ),
            SoftLabel(page.$5, icon: Icons.favorite),
            const SizedBox(height: 8),
            ReferenceArt(
              asset: page.$3,
              imageSize: const Size(390, 844),
              crop: page.$4,
              radius: 28,
            ),
            Text(
              page.$1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              page.$2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: tertiaryInk,
              ),
            ),
            const SizedBox(height: 28),
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
                      color: i == step ? hopelyBlueDark : surfaceHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  step < 2 ? setState(() => step++) : context.go('/role'),
              icon: const Icon(Icons.arrow_forward, size: 20),
              label: Text(step == 2 ? 'Mulai Sekarang' : 'Lanjut'),
            ),
          ],
        ),
      ),
    );
  }
}
