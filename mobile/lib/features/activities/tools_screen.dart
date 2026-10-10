import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/routing/navigation.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(),
      title: const Text('Tools Kesehatan'),
    ),
    body: PageBody(
      children: [
        const CareCard(
          color: skySoft,
          child: Heading(
            'Tools Kesehatanmu',
            'Panduan lembut untuk merawat tubuh dan pikiran hari ini.',
            badge: 'Ruang tenang & dukungan',
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 340
                ? constraints.maxWidth
                : (constraints.maxWidth - 14) / 2;
            return Wrap(
              spacing: 14,
              children: [
                _Tool(
                  'Aktivitas Relaksasi',
                  'Pilih kegiatan ringan sesuai kenyamananmu.',
                  Icons.air,
                  '/activities',
                  width,
                ),
                _Tool(
                  'Informasi Tepercaya',
                  'Cari informasi dari sumber terkurasi.',
                  Icons.menu_book_outlined,
                  '/knowledge',
                  width,
                ),
                _Tool(
                  'Jadwal Perawatan',
                  'Catat pengobatan dan konsultasi mendatang.',
                  Icons.calendar_month_outlined,
                  '/treatment',
                  width,
                ),
                _Tool(
                  'Ringkasan Dokter',
                  'Siapkan catatan untuk percakapan dengan tim perawatan.',
                  Icons.description_outlined,
                  '/doctor-summary',
                  width,
                ),
              ],
            );
          },
        ),
        const SectionHeading(
          'Kondisi Harianmu',
          icon: Icons.monitor_heart_outlined,
        ),
        SizedBox(
          height: 345,
          child: DataPage(
            load: () => ref.read(apiProvider).get('/symptoms'),
            builder: (data, reload) {
              final rows = items(data)
                ..sort(
                  (a, b) => (b['logged_at'] as String).compareTo(
                    a['logged_at'] as String,
                  ),
                );
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  CareCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (rows.isEmpty)
                          const Text('Belum ada keluhan fisik yang dicatat.')
                        else ...[
                          Text(
                            'Catatan terakhir: ${DateTime.parse(rows.first['logged_at']).toLocal().toString().substring(0, 16)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          ScoreBar('Nyeri', rows.first['pain'] as num?),
                          ScoreBar(
                            'Mual',
                            rows.first['nausea'] as num?,
                            color: Color(0xFF7846CE),
                          ),
                          ScoreBar(
                            'Nafsu makan',
                            rows.first['appetite'] as num?,
                          ),
                        ],
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () async {
                            await context.push('/symptoms');
                            reload();
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Catat Kondisi Fisik'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const PrivacyNote(
          'Ringkasan hanya dapat dilihat kerabat yang sudah terhubung dan mendapat izinmu. Mengisi catatan tidak otomatis mengaktifkan berbagi.',
        ),
      ],
    ),
  );
}

class _Tool extends StatelessWidget {
  const _Tool(this.title, this.subtitle, this.icon, this.route, this.width);
  final String title, subtitle, route;
  final IconData icon;
  final double width;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: CareCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openAppDestination(context, route),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: skySoft,
              child: Icon(icon, color: hopelyBlue),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Text(subtitle),
            const SizedBox(height: 12),
            const Icon(Icons.arrow_forward, color: hopelyBlue),
          ],
        ),
      ),
    ),
  );
}
