import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        final name = firstName(
          session.profile?['display_name'] ?? session.user?['name'] as String?,
        );
        final phase = session.profile?['treatment_phase']?.toString();
        return PageBody(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? dayGreeting() : '${dayGreeting()}, $name',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  phase?.isNotEmpty == true
                      ? phase!
                      : 'Hari ini, pelan-pelan saja.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            CareCard(
              color: skySoft,
              padding: 24,
              radius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconWell(Icons.favorite, size: 48, radius: 16, background: surfaceHighest),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bagaimana keadaanmu hari ini?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Luangkan 1 menit untuk mencatat kondisi fisik dan emosimu.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () async {
                        await context.push('/checkin');
                        reload();
                      },
                      child: Text(
                        today == null ? 'Check-in' : 'Perbarui Check-In',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (upcoming.isNotEmpty)
              CareCard(
                padding: 16,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 18, color: mutedInk),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Jadwal Berikutnya',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: mutedInk,
                            ),
                          ),
                        ),
                        SoftLabel(
                          relativeScheduleLabel(
                            DateTime.parse(upcoming.first['scheduled_at']),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                upcoming.first['title'],
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              if (upcoming.first['hospital_name']
                                      ?.toString()
                                      .isNotEmpty ==
                                  true)
                                Text(
                                  upcoming.first['hospital_name'],
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/treatment'),
                          child: const Row(
                            children: [
                              Text('Lihat'),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              CareCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Belum ada jadwal mendatang. Tambahkan di Perjalanan.',
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/treatment'),
                      child: const Text('Lihat'),
                    ),
                  ],
                ),
              ),
            CareCard(
              color: surfaceContainer,
              padding: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      IconWell(
                        Icons.psychology,
                        size: 44,
                        radius: 16,
                        background: Colors.white,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mau cerita?',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Hopely ada di sini untuk mendengarkan tanpa menghakimi.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: hopelyBlue,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => context.go('/chat'),
                      child: const Text('Mulai ngobrol'),
                    ),
                  ),
                ],
              ),
            ),
            const HomeRecommendation(),
            CareCard(
              color: skySoft,
              padding: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Support Circle',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SoftLabel('Aktif'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Temukan teman seperjalanan yang saling menguatkan.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ...List.generate(
                        3,
                        (i) => Transform.translate(
                          offset: Offset(-10.0 * i, 0),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: [primaryFixed, surfaceHigh, surfaceContainer][i],
                            child: Icon(
                              [
                                Icons.favorite_outline,
                                Icons.spa_outlined,
                                Icons.diversity_1_outlined,
                              ][i],
                              size: 18,
                              color: hopelyBlue,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: surfaceContainer,
                          foregroundColor: hopelyBlue,
                          shape: const StadiumBorder(),
                          minimumSize: const Size(88, 40),
                        ),
                        onPressed: () => context.push('/community'),
                        child: const Text('Masuk'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionLink('Insight', '/insights', icon: Icons.insights_outlined),
                ActionLink('Jurnal', '/journal', icon: Icons.edit_note),
                ActionLink('Tools', '/tools', icon: Icons.health_and_safety_outlined),
                ActionLink('Kerabat', '/care-circle', icon: Icons.people_outline),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.spa, size: 18, color: hopelyBlue),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Pelan-pelan saja, setiap langkahmu sangat berharga.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: mutedInk),
                    ),
                  ),
                ],
              ),
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
        return CareCard(
          child: Row(
            children: [
              const IconWell(Icons.air, size: 48, radius: 16),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('Pilihan personal belum tersedia.'),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: surfaceHigh,
                  foregroundColor: hopelyBlue,
                  shape: const StadiumBorder(),
                  minimumSize: const Size(72, 40),
                ),
                onPressed: () => context.push('/activities'),
                child: const Text('Mulai'),
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
        padding: 16,
        child: Row(
          children: [
            const IconWell(Icons.air, size: 48, radius: 16),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MockNotice(row['metadata']),
                  Text(
                    row['activity']['title'],
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    row['reason']?.toString() ??
                        '${row['activity']['duration_minutes']} menit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: surfaceHigh,
                foregroundColor: hopelyBlue,
                shape: const StadiumBorder(),
                minimumSize: const Size(72, 40),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ActivityDetail(recommendation: row),
                ),
              ),
              child: const Text('Mulai'),
            ),
          ],
        ),
      );
    },
  );
}
