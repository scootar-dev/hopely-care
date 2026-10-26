import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import 'activities_screen.dart';
import 'activity_image.dart';

class ActivityCatalogScreen extends ConsumerWidget {
  const ActivityCatalogScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Semua aktivitas')),
    body: DataPage(
      load: () => ref.read(apiProvider).get('/activities'),
      builder: (data, reload) => PageBody(
        children: [
          if (items(data).isEmpty)
            const CareCard(child: Text('Belum ada aktivitas tersedia.')),
          for (final row in items(data))
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ActivityImage(url: row['image_url']),
                  const SizedBox(height: 12),
                  Text(
                    row['title'],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('${row['duration_minutes']} menit • ${row['category']}'),
                  const SizedBox(height: 8),
                  Text(
                    row['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Lihat latihan'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ActivityDetail(recommendation: {'activity': row}),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
