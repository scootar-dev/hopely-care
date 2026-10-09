import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';
import '../../core/theme/theme.dart';

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
            Heading('Halo, $name', 'Bagaimana keadaanmu hari ini?'),
            if (session.profile?['treatment_phase']?.toString().isNotEmpty ==
                true)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: SoftLabel(
                  session.profile!['treatment_phase'],
                  icon: Icons.eco_outlined,
                ),
              ),
            BlueCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const SoftLabel('Check-in Harian', inverse: true),
                      SoftLabel(
                        today == null
                            ? 'Belum diisi hari ini'
                            : 'Tersimpan hari ini',
                        inverse: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Refleksi Tubuh & Pikiran',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    today == null
                        ? 'Luangkan waktu untuk mencatat perasaan dan fisikmu dengan lembut.'
                        : 'Terima kasih sudah mendengarkan dirimu. Suasana hati ${today['mood_score']}/5 • Energi ${today['energy_score']}/5.',
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: hopelyBlue,
                      ),
                      onPressed: () async {
                        await context.push('/checkin');
                        reload();
                      },
                      icon: const Icon(Icons.favorite_outline),
                      label: Text(
                        today == null
                            ? 'Mulai Check-In Sekarang'
                            : 'Perbarui Check-In',
                      ),
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
                          'Hopely AI siap mendengarkan',
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
                    'Butuh teman bercerita? Mulai dari apa yang terasa sekarang.',
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Aku merasa cemas'),
                        onPressed: () => context.go('/chat?prompt=anxiety'),
                      ),
                      ActionChip(
                        label: const Text('Cerita hari ini'),
                        onPressed: () => context.go('/chat?prompt=story'),
                      ),
                      ActionChip(
                        label: const Text('Latihan relaksasi'),
                        onPressed: () => context.push('/activities'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: pillBlue,
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: () => context.go('/chat'),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Mulai Obrolan dengan AI'),
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
            SectionHeading(
              'Tren Suasana Hati',
              action: 'Lihat analisis',
              onTap: () => context.go('/insights'),
            ),
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lima hari terakhir • laporan mandiri',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: List.generate(5, (i) {
                      final day = DateTime.now().subtract(
                        Duration(days: 4 - i),
                      );
                      final row = checkins
                          .where((c) => c['checkin_date'] == dateOnly(day))
                          .firstOrNull;
                      final score = row?['mood_score'] as int?;
                      const faces = [
                        Icons.sentiment_very_dissatisfied,
                        Icons.sentiment_dissatisfied,
                        Icons.sentiment_neutral,
                        Icons.sentiment_satisfied,
                        Icons.sentiment_very_satisfied,
                      ];
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: skySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${day.day}/${day.month}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(height: 12),
                              Icon(
                                score == null
                                    ? Icons.edit_outlined
                                    : faces[(score - 1).clamp(0, 4)],
                                color: hopelyBlue,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                score == null ? '—' : '$score / 5',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SectionHeading('Ruang Dukungan', icon: Icons.spa_outlined),
            const HomeRecommendation(),
            const CareCard(
              child: Column(
                children: [
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
              'Hopely Care mendampingi wellbeing dan membantu pencatatan. Untuk keluhan medis, hubungi tim perawatanmu.',
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
            const ActionLink(
              'Mulai aktivitas',
              '/activities',
              icon: Icons.play_circle_outline,
            ),
          ],
        ),
      );
    },
  );
}
