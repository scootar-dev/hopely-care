import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/theme/theme.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Ruang untuk Dirimu')),
    body: DataPage(
      load: () => ref.read(apiProvider).get('/activities/recommended'),
      builder: (data, reload) {
        final rows = items(data);
        return PageBody(
          children: [
            const Heading(
              'Pelan-pelan saja',
              'Pilihan dari pustaka aktivitas dukungan. Kamu bebas memilih atau melewatinya.',
            ),
            if (rows.isEmpty)
              const CareCard(
                child: Text(
                  'Belum ada aktivitas yang dipilih. Kamu bisa kembali nanti.',
                ),
              ),
            for (final row in rows) ...[
              MockNotice(row['metadata']),
              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.spa_outlined, color: forest),
                    const SizedBox(height: 8),
                    Text(
                      row['activity']['title'],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${row['activity']['duration_minutes']} menit • ${row['reason']}',
                    ),
                    const SizedBox(height: 12),
                    Text(row['activity']['description']),
                    if (row['activity']['contraindication_notes'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(row['activity']['contraindication_notes']),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ActivityDetail(recommendation: row),
                        ),
                      ),
                      child: const Text('Mulai dengan nyaman'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}

class ActivityDetail extends ConsumerStatefulWidget {
  const ActivityDetail({super.key, required this.recommendation});
  final Json recommendation;
  @override
  ConsumerState<ActivityDetail> createState() => _ActivityDetailState();
}

class _ActivityDetailState extends ConsumerState<ActivityDetail> {
  bool busy = false, completed = false;
  Object? error;
  Future<void> complete() async {
    setState(() => busy = true);
    try {
      await ref
          .read(apiProvider)
          .post('/activities/${widget.recommendation['id']}/complete');
      if (mounted) {
        setState(() => completed = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e);
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.recommendation['activity'];
    return Scaffold(
      appBar: AppBar(title: const Text('Waktu untuk Dirimu')),
      body: PageBody(
        children: [
          Heading(activity['title'], 'Lakukan hanya selama terasa nyaman.'),
          for (final step in activity['steps'] as List)
            CareCard(child: Text(step)),
          const Text('Kamu boleh berhenti kapan saja.'),
          const SizedBox(height: 24),
          if (error != null) ErrorNotice(error!),
          FilledButton(
            onPressed: busy || completed ? null : complete,
            child: Text(
              completed
                  ? 'Sudah dicatat selesai'
                  : busy
                  ? 'Menyimpan…'
                  : 'Tandai selesai',
            ),
          ),
        ],
      ),
    );
  }
}
