import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'stitch.dart';
import '../routing/navigation.dart';

class FeatureRail extends StatelessWidget {
  const FeatureRail({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Material(
        color: Colors.white,
        child: SizedBox(
          width: 80,
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: HopelyMark(size: 36),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final item in const [
                          (Icons.home_outlined, 'Beranda', '/home'),
                          (
                            Icons.calendar_today_outlined,
                            'Perjalanan',
                            '/treatment',
                          ),
                          (Icons.chat_bubble_outline, 'Hopely AI', '/chat'),
                          (Icons.insights_outlined, 'Insight', '/insights'),
                          (Icons.groups_outlined, 'Komunitas', '/community'),
                          (Icons.book_outlined, 'Jurnal', '/journal'),
                          (
                            Icons.self_improvement_outlined,
                            'Aktivitas',
                            '/activities',
                          ),
                          (Icons.info_outline, 'Informasi', '/knowledge'),
                        ])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: IconButton(
                              tooltip: item.$2,
                              onPressed: () =>
                                  openAppDestination(context, item.$3),
                              icon: Icon(item.$1),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    tooltip: 'Bantuan Cepat',
                    icon: const Icon(Icons.shield_outlined),
                    onPressed: () => context.go('/quick-help'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Expanded(child: child),
    ],
  );
}
