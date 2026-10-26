import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';

class ArticleScreen extends ConsumerWidget {
  const ArticleScreen({super.key, this.id});
  final String? id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(id == null ? 'Pustaka artikel' : 'Artikel terkurasi'),
    ),
    body: DataPage(
      load: () => ref
          .read(apiProvider)
          .get('/knowledge/articles${id == null ? '' : '/$id'}'),
      builder: (data, reload) => PageBody(
        children: id == null
            ? [
                if (items(data).isEmpty)
                  const CareCard(
                    child: Text(
                      'Belum ada artikel terbit. Dokumen yang ditambahkan admin akan muncul di sini.',
                    ),
                  ),
                for (final row in items(data))
                  CareCard(
                    child: ListTile(
                      title: Text(row['title']),
                      subtitle: Text(row['publisher']),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push('/knowledge/articles/${row['id']}'),
                    ),
                  ),
              ]
            : [
                Text(
                  data['title'],
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text('Penerbit: ${data['publisher']}'),
                Text(
                  'Ditinjau oleh: ${data['reviewed_by']} • Versi ${data['document_version']}',
                ),
                if (data['source_url'] != null)
                  SelectableText(data['source_url']),
                const SizedBox(height: 20),
                CareCard(child: SelectableText(data['text'])),
              ],
      ),
    ),
  );
}
