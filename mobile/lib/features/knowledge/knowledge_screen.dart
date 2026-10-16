import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/stitch.dart';
import '../../core/widgets/ui.dart';

class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});
  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  final query = TextEditingController();
  bool busy = false;
  Object? error;
  Json? answer;
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> ask() async {
    if (query.text.trim().isEmpty) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
      answer = null;
    });
    try {
      final data =
          await ref.read(apiProvider).post('/knowledge/query', {
                'question': query.text,
              })
              as Json;
      if (mounted) {
        setState(() => answer = data);
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(),
      title: const Text('Informasi Tepercaya'),
      actions: const [
        Padding(padding: EdgeInsets.all(10), child: HopelyMark()),
      ],
    ),
    body: PageBody(
      children: [
        CareCard(
          color: skySoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SoftLabel(
                'Diverifikasi tim kesehatan',
                icon: Icons.verified_outlined,
              ),
              const SizedBox(height: 12),
              Text(
                'Informasi tepercaya',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Pustaka edukasi yang tenang, sahih, dan dirancang khusus untuk mendampingimu.',
              ),
            ],
          ),
        ),
        TextField(
          controller: query,
          maxLines: 1,
          textInputAction: TextInputAction.search,
          onSubmitted: busy ? null : (_) => ask(),
          decoration: InputDecoration(
            hintText: 'Cari informasi kesehatan...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: busy ? null : ask,
              icon: const Icon(Icons.tune),
              tooltip: 'Cari sumber',
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy ? null : ask,
          child: Text(busy ? 'Mencari sumber…' : 'Cari informasi'),
        ),
        const SizedBox(height: 24),
        const SectionHeading('Jelajahi topik kesehatan'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            Chip(label: Text('Semua')),
            Chip(label: Text('Perawatan')),
            Chip(label: Text('Efek samping')),
          ],
        ),
        if (error != null) ErrorNotice(error!),
        if (answer != null) ...[
          MockNotice(answer!['metadata']),
          const SectionHeading(
            'Jawaban dari sumber terkurasi',
            icon: Icons.auto_awesome_outlined,
          ),
          BlueCard(
            child: Text(
              answer!['answer'],
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SectionHeading('Sumber yang digunakan', icon: Icons.menu_book),
          for (final source in answer!['sources'] as List)
            CareCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const IconWell(Icons.menu_book_outlined, size: 44),
                title: Text(source['title']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${source['publisher']}\nVersi sumber: ${source['document_version']}',
                    ),
                    if (source['source_url'] != null)
                      SelectableText(source['source_url']),
                  ],
                ),
                isThreeLine: true,
              ),
            ),
        ],
      ],
    ),
  );
}
