import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import 'checkin_screen.dart';

class RecordHistoryScreen extends ConsumerStatefulWidget {
  const RecordHistoryScreen({super.key});
  @override
  ConsumerState<RecordHistoryScreen> createState() => _RecordHistoryState();
}

class _RecordHistoryState extends ConsumerState<RecordHistoryScreen> {
  String kind = 'checkins';
  int page = 1, revision = 0;
  Future<void> remove(Json row) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: const Text('Catatan yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await ref.read(apiProvider).delete('/$kind/${row['id']}');
      if (mounted) {
        setState(() {
          page = 1;
          revision++;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Riwayat Tracking')),
    body: DataPage(
      key: ValueKey('$kind:$page:$revision'),
      load: () => ref.read(apiProvider).get('/$kind?page=$page'),
      builder: (data, reload) => PageBody(
        children: [
          const Heading(
            'Catatan perjalananmu',
            'Lihat, perbarui, atau hapus catatan yang kamu simpan.',
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'checkins', label: Text('Check-in')),
              ButtonSegment(value: 'symptoms', label: Text('Gejala')),
            ],
            selected: {kind},
            onSelectionChanged: (v) => setState(() {
              kind = v.first;
              page = 1;
            }),
          ),
          const SizedBox(height: 16),
          if (items(data).isEmpty)
            const CareCard(child: Text('Belum ada catatan.')),
          for (final row in items(data))
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${row[kind == 'checkins' ? 'checkin_date' : 'logged_at']}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final key
                      in kind == 'checkins'
                          ? [
                              'mood_score',
                              'anxiety_score',
                              'energy_score',
                              'sleep_score',
                              'pain_score',
                            ]
                          : [
                              'pain',
                              'fatigue',
                              'nausea',
                              'dizziness',
                              'appetite',
                              'sleep_quality',
                            ])
                    Text(
                      '${const {'mood_score': 'Suasana hati', 'anxiety_score': 'Kecemasan', 'energy_score': 'Energi', 'sleep_score': 'Tidur', 'pain_score': 'Nyeri', 'pain': 'Nyeri', 'fatigue': 'Lelah', 'nausea': 'Mual', 'dizziness': 'Pusing', 'appetite': 'Nafsu makan', 'sleep_quality': 'Kualitas tidur'}[key]}: ${row[key]}/5',
                    ),
                  if ((row['optional_note'] ?? '').toString().isNotEmpty)
                    Text(row['optional_note']),
                  if (row['emotion_signal'] is Map) ...[
                    MockNotice(row['emotion_signal']['metadata']),
                    const Divider(),
                    Text(
                      'Refleksi emosi: ${row['emotion_signal']['primary_emotion']}',
                    ),
                    if (row['emotion_signal']['scores'] is Map)
                      for (final e
                          in (row['emotion_signal']['scores'] as Map).entries)
                        Text('${e.key}: ${e.value}'),
                  ],
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Ubah'),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CheckinScreen(
                                symptoms: kind == 'symptoms',
                                entry: row,
                              ),
                            ),
                          );
                          if (mounted) setState(() => revision++);
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus'),
                        onPressed: () => remove(row),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: page > 1 ? () => setState(() => page--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Halaman $page / ${data['last_page']}'),
              IconButton(
                onPressed: page < (data['last_page'] as int)
                    ? () => setState(() => page++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
