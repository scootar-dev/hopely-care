import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';
import '../../core/theme/theme.dart';
import '../activities/activities_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(apiProvider), session = ref.watch(sessionProvider);
    return DataPage(
      load: () async => {
        'checkins': await api.get('/checkins'),
        'treatments': await api.get('/treatments'),
      },
      builder: (data, reload) {
        final checkins = items(data['checkins']);
        final today = checkins
            .where((c) => c['checkin_date'] == dateOnly(DateTime.now()))
            .firstOrNull;
        final upcoming =
            items(data['treatments'])
                .where(
                  (t) =>
                      t['status'] == 'scheduled' &&
                      DateTime.parse(t['scheduled_at']).isAfter(DateTime.now()),
                )
                .toList()
              ..sort(
                (a, b) => (a['scheduled_at'] as String).compareTo(
                  b['scheduled_at'] as String,
                ),
              );
        final name =
            session.profile?['display_name'] ?? session.user?['name'] ?? '';
        return PageBody(
          children: [
            Heading('Halo, $name', 'Senang bertemu denganmu hari ini.'),
            if (session.profile?['treatment_phase']?.toString().isNotEmpty ==
                true)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: SoftLabel(
                  session.profile!['treatment_phase'],
                  icon: Icons.eco_outlined,
                ),
              ),
            CareCard(
              color: skySoft,
              padding: 24,
              radius: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.favorite_outline, color: hopelyBlue, size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Bagaimana keadaanmu hari ini?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    today == null
                        ? 'Luangkan 1 menit untuk mencatat kondisi fisik dan emosimu.'
                        : 'Catatan hari ini tersimpan. Kamu dapat memperbaruinya kapan saja.',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await context.push('/checkin');
                        reload();
                      },
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: Text(
                        today == null ? 'Check-in' : 'Perbarui Check-In',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SectionHeading(
              'Jadwal Mendatang',
              icon: Icons.calendar_month_outlined,
              action: 'Lihat semua',
              onTap: () => context.go('/treatment'),
            ),
            if (upcoming.isEmpty)
              const CareCard(
                child: Text(
                  'Belum ada jadwal mendatang. Tambahkan jadwal di Perjalanan.',
                ),
              )
            else
              CareCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: skySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        DateFormat('dd\nMM').format(
                          DateTime.parse(
                            upcoming.first['scheduled_at'],
                          ).toLocal(),
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: hopelyBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            upcoming.first['title'],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('dd/MM/yyyy • HH:mm').format(
                              DateTime.parse(
                                upcoming.first['scheduled_at'],
                              ).toLocal(),
                            ),
                          ),
                          if (upcoming.first['hospital_name']
                                  ?.toString()
                                  .isNotEmpty ==
                              true)
                            Text(upcoming.first['hospital_name']),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            CareCard(
              color: skySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      HopelyMark(),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mau cerita?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Hopely ada di sini untuk mendengarkan tanpa menghakimi.',
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: () => context.go('/chat'),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Mulai ngobrol'),
                    ),
                  ),
                ],
              ),
            ),
            const HomeRecommendation(),
            CareCard(
              color: skySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.diversity_1_outlined,
                        color: Color(0xFF1E40AF),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Support Circle',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Temukan orang-orang yang memahami perjalananmu.'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push('/community'),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Masuk Komunitas'),
                  ),
                ],
              ),
            ),
            const CareCard(
              child: Column(
                children: [
                  ActionLink(
                    'Lihat insight',
                    '/insights',
                    icon: Icons.insights_outlined,
                  ),
                  ActionLink(
                    'Tulis jurnal pribadi',
                    '/journal',
                    icon: Icons.edit_note,
                  ),
                  ActionLink(
                    'Jelajahi Tools Kesehatan',
                    '/tools',
                    icon: Icons.health_and_safety_outlined,
                  ),
                  ActionLink(
                    'Undang kerabat tepercaya',
                    '/care-circle',
                    icon: Icons.people_outline,
                  ),
                ],
              ),
            ),
            const PrivacyNote(
              'Pelan-pelan saja, setiap langkahmu sangat berharga.',
            ),
          ],
        );
      },
    );
  }
}

class HomeRecommendation extends ConsumerStatefulWidget {
  const HomeRecommendation({super.key});
  @override
  ConsumerState<HomeRecommendation> createState() => _HomeRecommendationState();
}

class _HomeRecommendationState extends ConsumerState<HomeRecommendation> {
  late final Future<dynamic> recommendation = ref
      .read(apiProvider)
      .get('/activities/recommended');
  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: recommendation,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const CareCard(
          child: Column(
            children: [
              Text('Pilihan personal belum tersedia.'),
              ActionLink(
                'Buka aktivitas dukungan',
                '/activities',
                icon: Icons.spa_outlined,
              ),
            ],
          ),
        );
      }
      if (!snapshot.hasData) {
        return const LinearProgressIndicator();
      }
      final rows = items(snapshot.data);
      if (rows.isEmpty) {
        return const SizedBox.shrink();
      }
      final row = rows.first;
      return CareCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MockNotice(row['metadata']),
            Text(
              row['activity']['title'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${row['activity']['duration_minutes']} menit • ${row['reason']}',
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ActivityDetail(recommendation: row),
                ),
              ),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Mulai aktivitas'),
            ),
          ],
        ),
      );
    },
  );
}
