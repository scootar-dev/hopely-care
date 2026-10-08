import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/theme/theme.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});
  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  int days = 14;
  @override
  Widget build(BuildContext context) => DataPage(
    key: ValueKey(days),
    load: () => ref.read(apiProvider).get('/insights?days=$days'),
    builder: (data, reload) {
      final rows = items(data['series']);
      final metrics = data['metrics'] as Json;
      return PageBody(
        children: [
          if (data['contains_mock_signals'] == true)
            const MockNotice({'mode': 'mock'}),
          const Heading(
            'Tren Kesejahteraanmu',
            'Melihat pola emosional dan fisik dari catatanmu.',
          ),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7 Hari')),
              ButtonSegment(value: 14, label: Text('14 Hari')),
            ],
            selected: {days},
            onSelectionChanged: (v) => setState(() => days = v.first),
          ),
          const SizedBox(height: 24),
          CareCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emosi dari hari ke hari',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${data['recorded_days']} dari $days hari tercatat'),
                const SizedBox(height: 24),
                if (rows.length < 2)
                  const Text(
                    'Tambahkan catatan pada hari berikutnya untuk melihat grafik.',
                  )
                else
                  Semantics(
                    label:
                        'Grafik skor laporan mandiri. Nilai setiap metrik tersedia pada ringkasan di bawah.',
                    child: SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: CustomPaint(painter: TrendPainter(rows)),
                    ),
                  ),
                const SizedBox(height: 16),
                const Wrap(
                  spacing: 12,
                  children: [
                    Text('● Cemas', style: TextStyle(color: Color(0xFFA94316))),
                    Text('● Tidur', style: TextStyle(color: Colors.blueGrey)),
                    Text('● Mood', style: TextStyle(color: forest)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Skala 1–5 • hanya tanggal yang tercatat'),
              ],
            ),
          ),
          if (data['overall_direction'] == 'insufficient_data')
            const CareCard(
              color: mint,
              child: Text(
                'Catatan belum cukup untuk menyimpulkan arah tren. Dibutuhkan setidaknya 7 hari tercatat, termasuk data terbaru.',
              ),
            ),
          Text(
            'Yang terlihat dari catatanmu',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          for (final key in ['mood', 'anxiety', 'energy', 'sleep', 'pain'])
            CareCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      const {
                        'mood': 'Suasana hati',
                        'anxiety': 'Kecemasan',
                        'energy': 'Energi',
                        'sleep': 'Kualitas tidur',
                        'pain': 'Nyeri',
                      }[key]!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        metrics[key]['mean'] == null
                            ? 'Belum tercatat'
                            : '${metrics[key]['mean']} / 5',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        const {
                              'increasing': 'Meningkat',
                              'declining': 'Menurun',
                              'stable': 'Relatif stabil',
                              'insufficient_data': 'Belum cukup data',
                            }[metrics[key]['direction']] ??
                            '',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          for (final pattern in data['contextual_patterns'] as List)
            CareCard(child: Text(pattern['observation'])),
          const CareCard(
            color: forest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Persiapan Konsultasi Medis',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                SizedBox(height: 8),
                Text(
                  'Bawa catatanmu untuk membantu percakapan dengan tim perawatan.',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 8),
                _SummaryLink(),
              ],
            ),
          ),
          const Text(
            'Diolah dari laporan mandiri, bukan diagnosis atau bukti sebab-akibat medis.',
          ),
        ],
      );
    },
  );
}

class _SummaryLink extends StatelessWidget {
  const _SummaryLink();
  @override
  Widget build(BuildContext context) => const CareCard(
    padding: 0,
    child: ActionLink(
      'Buat rangkuman untuk dokter',
      '/doctor-summary',
      icon: Icons.description_outlined,
    ),
  );
}

class TrendPainter extends CustomPainter {
  TrendPainter(this.rows);
  final List<Json> rows;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE6ECE8)
      ..strokeWidth = 1;
    for (var v = 1; v <= 5; v++) {
      final y = 10 + (5 - v) / 4 * (size.height - 35);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final sorted = [...rows]
      ..sort(
        (a, b) => (a['checkin_date'] as String).compareTo(
          b['checkin_date'] as String,
        ),
      );
    final first = DateTime.parse(sorted.first['checkin_date']);
    final span = DateTime.parse(
      sorted.last['checkin_date'],
    ).difference(first).inDays.clamp(1, 365);
    for (final entry in {
      'anxiety_score': const Color(0xFFA94316),
      'sleep_score': Colors.blueGrey,
      'mood_score': forest,
    }.entries) {
      final paint = Paint()
        ..color = entry.value
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < sorted.length; i++) {
        Offset point(Json r) => Offset(
          DateTime.parse(r['checkin_date']).difference(first).inDays /
              span *
              size.width,
          10 + (5 - (r[entry.key] as num)) / 4 * (size.height - 35),
        );
        final p = point(sorted[i]);
        canvas.drawCircle(p, 3, Paint()..color = entry.value);
        // Gaps remain visible rather than implying observations on missing days.
        if (i > 0 &&
            DateTime.parse(sorted[i]['checkin_date'])
                    .difference(DateTime.parse(sorted[i - 1]['checkin_date']))
                    .inDays ==
                1) {
          canvas.drawLine(point(sorted[i - 1]), p, paint);
        }
      }
    }
    final label = TextPainter(
      text: TextSpan(
        text:
            '${sorted.first['checkin_date']}   →   ${sorted.last['checkin_date']}',
        style: const TextStyle(fontSize: 11, color: ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    label.paint(canvas, Offset(0, size.height - 16));
  }

  @override
  bool shouldRepaint(covariant TrendPainter oldDelegate) =>
      oldDelegate.rows != rows;
}
