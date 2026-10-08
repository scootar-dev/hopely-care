import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
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
    appBar: AppBar(title: const Text('Informasi Tepercaya')),
    body: PageBody(
      children: [
        const Heading(
          'Memahami dengan sumber',
          'Informasi umum dari dokumen terkurasi. Keputusan perawatan tetap bersama tim kesehatanmu.',
        ),
        TextField(
          controller: query,
          maxLines: 3,
          maxLength: 2000,
          decoration: const InputDecoration(
            hintText: 'Apa yang ingin kamu pahami?',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy ? null : ask,
          child: Text(busy ? 'Mencari sumber…' : 'Cari informasi'),
        ),
        const SizedBox(height: 24),
        if (error != null) ErrorNotice(error!),
        if (answer != null) ...[
          MockNotice(answer!['metadata']),
          CareCard(child: Text(answer!['answer'])),
          for (final source in answer!['sources'] as List)
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source['title'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(source['publisher']),
                  if (source['source_url'] != null)
                    SelectableText(source['source_url']),
                  Text('Versi sumber: ${source['document_version']}'),
                ],
              ),
            ),
        ],
      ],
    ),
  );
}
