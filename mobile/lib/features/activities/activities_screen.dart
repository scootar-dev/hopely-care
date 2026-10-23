import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/account_action.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(),
      title: const Text('Untukmu'),
      actions: const [
        AccountAction(),
      ],
    ),
    body: DataPage(
      load: () => ref.read(apiProvider).get('/activities/recommended'),
      builder: (data, reload) {
        final rows = items(data);
        return PageBody(
          children: [
            CareCard(
              color: skySoft,
              padding: 20,
              child: Row(
                children: [
                  const IconWell(
                    Icons.spa_outlined,
                    size: 52,
                    radius: 28,
                    background: hopelyBlue,
                    foreground: Colors.white,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SANCTUARI MANDIRI',
                          style: TextStyle(
                            color: hopelyBlue,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ruang tenang untuk mengistirahatkan tubuh dan pikiran.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeading('Rekomendasi Lembut Hari Ini'),
            if (rows.isEmpty)
              const CareCard(
                child: Text(
                  'Belum ada aktivitas yang dipilih. Kamu bisa kembali nanti.',
                ),
              ),
            for (final row in rows) ...[
              MockNotice(row['metadata']),
              CareCard(
                padding: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconWell(_activityIcon(row['activity']['category'])),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            row['activity']['title'],
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
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
                    FilledButton.icon(
                    onPressed: () => context.push('/activities/${row['id']}'),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Mulai dengan nyaman'),
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                      ),
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

IconData _activityIcon(dynamic category) {
  switch (category?.toString().toLowerCase()) {
    case 'breathing':
    case 'napas':
      return Icons.air;
    case 'grounding':
    case 'senses':
      return Icons.self_improvement_outlined;
    case 'reflection':
    case 'journal':
      return Icons.edit_note_outlined;
    default:
      return Icons.spa_outlined;
  }
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
      appBar: AppBar(
        leading: const BackHomeButton(),
        title: const Text('Waktu untuk Dirimu'),
      ),
      body: PageBody(
        children: [
          Heading(
            activity['title'],
            'Lakukan hanya selama terasa nyaman.',
            badge: 'AKTIVITAS LEMBUT',
          ),
          for (
            var index = 0;
            index < (activity['steps'] as List).length;
            index++
          )
            CareCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: lavender,
                    foregroundColor: hopelyBlue,
                    child: Text('${index + 1}'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text((activity['steps'] as List)[index].toString()),
                  ),
                ],
              ),
            ),
          const CareCard(
            color: skySoft,
            child: Row(
              children: [
                Icon(Icons.favorite_border, color: hopelyBlue),
                SizedBox(width: 10),
                Expanded(child: Text('Kamu boleh berhenti kapan saja.')),
              ],
            ),
          ),
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
