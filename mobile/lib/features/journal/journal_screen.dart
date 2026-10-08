import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});
  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  int version = 0;
  void edit([Json? entry]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => JournalEditor(entry: entry)),
    );
    if (mounted) {
      setState(() => version++);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Jurnal Pribadi')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: edit,
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Tulis jurnal'),
    ),
    body: DataPage(
      key: ValueKey(version),
      load: () => ref.read(apiProvider).get('/journals'),
      builder: (data, reload) {
        final rows = items(data);
        return PageBody(
          children: [
            const Heading(
              'Ruang untuk ceritamu',
              'Isi jurnal hanya untukmu. Analisis AI selalu memerlukan izinmu.',
            ),
            if (rows.isEmpty)
              const CareCard(
                child: Text(
                  'Belum ada cerita tersimpan. Mulai kapan pun kamu siap.',
                ),
              ),
            for (final row in rows)
              CareCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    row['title']?.toString().isNotEmpty == true
                        ? row['title']
                        : 'Catatan ${row['journal_date']}',
                  ),
                  subtitle: Text(
                    row['content'],
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => edit(row),
                ),
              ),
            const SizedBox(height: 80),
          ],
        );
      },
    ),
  );
}

class JournalEditor extends ConsumerStatefulWidget {
  const JournalEditor({super.key, this.entry});
  final Json? entry;
  @override
  ConsumerState<JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends ConsumerState<JournalEditor> {
  final title = TextEditingController(), body = TextEditingController();
  bool analysis = false, busy = false;
  Object? error;
  Json? insight;
  String? id;
  @override
  void initState() {
    super.initState();
    title.text = widget.entry?['title'] ?? '';
    body.text = widget.entry?['content'] ?? '';
    analysis = widget.entry?['ai_analysis_allowed'] == true;
    id = widget.entry?['id'];
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (body.text.trim().isEmpty) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
      insight = null;
    });
    try {
      final api = ref.read(apiProvider);
      final Json payload = {
        'title': title.text,
        'content': body.text,
        'journal_date':
            widget.entry?['journal_date'] ?? dateOnly(DateTime.now()),
        'ai_analysis_allowed':
            analysis &&
            ref.read(sessionProvider).consents.contains('AI_JOURNAL_ANALYSIS'),
      };
      final row = id == null
          ? await api.post('/journals', payload)
          : await api.put('/journals/$id', payload);
      id = row['id'];
      if (analysis &&
          ref.read(sessionProvider).consents.contains('AI_JOURNAL_ANALYSIS')) {
        insight = await api.post('/journals/$id/analyze') as Json;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jurnal tersimpan secara pribadi.')),
        );
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

  Future<void> remove() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus jurnal ini?'),
        content: const Text('Catatan dan hasil analisisnya akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true) {
      return;
    }
    try {
      await ref.read(apiProvider).delete('/journals/$id');
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = ref
        .read(sessionProvider)
        .consents
        .contains('AI_JOURNAL_ANALYSIS');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ceritamu Hari Ini'),
        actions: [
          if (id != null)
            IconButton(
              onPressed: busy ? null : remove,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus jurnal',
            ),
        ],
      ),
      body: PageBody(
        children: [
          TextField(
            controller: title,
            maxLength: 150,
            decoration: const InputDecoration(labelText: 'Judul (opsional)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: body,
            minLines: 8,
            maxLines: 16,
            maxLength: 12000,
            decoration: const InputDecoration(
              hintText: 'Apa yang paling terasa hari ini?',
            ),
          ),
          const SizedBox(height: 16),
          CareCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Izinkan Hopely AI menganalisis jurnal ini',
                  ),
                  subtitle: const Text('Tidak dibagikan kepada pendamping.'),
                  value: analysis && allowed,
                  onChanged: allowed
                      ? (v) => setState(() => analysis = v)
                      : null,
                ),
                if (!allowed)
                  const ActionLink(
                    'Aktifkan izin analisis di Privasi',
                    '/privacy',
                  ),
              ],
            ),
          ),
          if (error != null) ErrorNotice(error!),
          if (insight != null) ...[
            MockNotice(insight!['metadata']),
            CareCard(
              child: Text(
                'Sinyal emosi: ${insight!['primary_emotion']}\n${(insight!['themes'] as List).join(', ')}\nIni bukan diagnosis.',
              ),
            ),
          ],
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Menyimpan…' : 'Simpan jurnal'),
          ),
        ],
      ),
    );
  }
}
