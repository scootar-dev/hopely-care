import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
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
                (a, b) => a['scheduled_at'].compareTo(b['scheduled_at']) as int,
              );
        return PageBody(
          children: [
            Heading(
              'Halo, ${session.profile?['display_name'] ?? session.user?['name'] ?? ''}',
              'Semangat hari ini, langkah kecilmu sangat berarti.',
              badge: 'Ruang tenang pribadimu',
            ),
            const CareCard(
              color: hopelyBlue,
              borderColor: hopelyBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    avatar: Icon(Icons.lightbulb_outline, size: 16),
                    label: Text('Kata penyemangat hari ini'),
                    backgroundColor: Color(0xFF4E82F2),
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    side: BorderSide.none,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Setiap langkah kecil adalah kemenangan besar. Istirahatlah saat lelah, tapi jangan ragu bahwa kamu sangat berani.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    '- Tim Hopely Care',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (upcoming.isNotEmpty)
              CareCard(
                color: skySoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.circle, color: Color(0xFFD33131), size: 10),
                        SizedBox(width: 8),
                        Text(
                          'Jadwal perawatan terdekat',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      upcoming.first['title'],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      DateTime.parse(
                        upcoming.first['scheduled_at'],
                      ).toLocal().toString().substring(0, 16),
                    ),
                    const SizedBox(height: 8),
                    const ActionLink(
                      'Lihat perjalanan perawatan',
                      '/treatment',
                      icon: Icons.calendar_month_outlined,
                    ),
                  ],
                ),
              ),
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Chip(
                    label: Text('Refleksi hati - sekitar 1 menit'),
                    backgroundColor: lavender,
                    side: BorderSide.none,
                  ),
                  Text(
                    today == null
                        ? 'Bagaimana keadaanmu hari ini?'
                        : 'Terima kasih sudah mendengarkan dirimu.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    today == null
                        ? 'Tidak ada jawaban yang salah. Mulai dari apa yang terasa sekarang.'
                        : 'Suasana hati ${today['mood_score']}/5 - Energi ${today['energy_score']}/5',
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await context.push('/checkin');
                        reload();
                      },
                      icon: const Icon(Icons.favorite_border),
                      label: Text(
                        today == null
                            ? 'Check-In Sekarang'
                            : 'Perbarui Check-In',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CareCard(
              color: lavenderSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: lavender,
                    child: Icon(Icons.auto_awesome, color: hopelyBlue),
                  ),
                  const SizedBox(height: 12),
                  Text('Halo, aku Hopi', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Teman tenang untuk mendengarkan ceritamu tanpa menghakimi.',
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => context.go('/chat'),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Bicara dengan Hopely'),
                  ),
                ],
              ),
            ),
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Teman perjalanan', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Expanded(
                        child: _HomeShortcut(
                          label: 'Aktivitas',
                          subtitle: 'Dukungan',
                          route: '/activities',
                          icon: Icons.spa_outlined,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _HomeShortcut(
                          label: 'Jurnal',
                          subtitle: 'Catat rasa',
                          route: '/journal',
                          icon: Icons.edit_note,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _HomeShortcut(
                          label: 'Gejala',
                          subtitle: 'Kesehatan',
                          route: '/symptoms',
                          icon: Icons.monitor_heart_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const HomeSignals(),
            const CareCard(
              color: skySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pola emosimu dari hari ke hari',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text('Lihat perubahan dari catatan yang sudah kamu buat.'),
                  ActionLink(
                    'Buka wawasan',
                    '/insights',
                    icon: Icons.show_chart,
                  ),
                ],
              ),
            ),
            const CareCard(
              child: Column(
                children: [
                  ActionLink(
                    'Atur pendamping tepercaya',
                    '/care-circle',
                    icon: Icons.people_outline,
                  ),
                  ActionLink(
                    'Informasi dari sumber terkurasi',
                    '/knowledge',
                    icon: Icons.menu_book_outlined,
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

class _HomeShortcut extends StatelessWidget {
  const _HomeShortcut({
    required this.label,
    required this.subtitle,
    required this.route,
    required this.icon,
  });
  final String label, subtitle, route;
  final IconData icon;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: () => context.push(route),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDFC)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: lavender,
            child: Icon(icon, color: hopelyBlue),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class HomeSignals extends ConsumerStatefulWidget {
  const HomeSignals({super.key});
  @override
  ConsumerState<HomeSignals> createState() => _HomeSignalsState();
}

class _HomeSignalsState extends ConsumerState<HomeSignals> {
  late Future<dynamic> trend;
  late Future<dynamic> recommendation;
  @override
  void initState() {
    super.initState();
    final api = ref.read(apiProvider);
    trend = api.get('/insights?days=14');
    recommendation = api.get('/activities/recommended');
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      FutureBuilder<dynamic>(
        future: trend,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const CareCard(
              child: Text(
                'Wawasan belum tersedia. Kamu tetap dapat menyimpan catatan.',
              ),
            );
          }
          if (!snapshot.hasData) {
            return const LinearProgressIndicator();
          }
          final data = snapshot.data;
          return CareCard(
            color: skySoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan 14 hari terakhir',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (data['contains_mock_signals'] == true)
                  const MockNotice({'mode': 'mock'}),
                Text(
                  data['overall_direction'] == 'insufficient_data'
                      ? 'Catatan belum cukup untuk menunjukkan arah perubahan.'
                      : 'Rata-rata suasana hati: ${data['metrics']['mood']['mean']} / 5. Berdasarkan ${data['recorded_days']} hari tercatat.',
                ),
                const ActionLink(
                  'Lihat pola lengkap',
                  '/insights',
                  icon: Icons.show_chart,
                ),
              ],
            ),
          );
        },
      ),
      FutureBuilder<dynamic>(
        future: recommendation,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const CareCard(
              child: Text('Pilihan personal belum tersedia. Coba lagi nanti.'),
            );
          }
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
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
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${row['activity']['duration_minutes']} menit - ${row['reason']}',
                ),
                const ActionLink(
                  'Lihat aktivitas dukungan',
                  '/activities',
                  icon: Icons.spa_outlined,
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}
