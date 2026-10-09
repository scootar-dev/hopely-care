import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';
import '../../core/theme/theme.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});
  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  int version = 0, page = 1;
  void edit([Json? entry, bool letter = false]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JournalEditor(
          entry: entry,
          initialTitle: letter ? 'Surat untuk diriku' : '',
        ),
      ),
    );
    if (mounted) {
      setState(() => version++);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(),
      title: const Text('Jurnal Harian'),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: edit,
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Tulis Jurnal Baru'),
    ),
    body: DataPage(
      key: ValueKey('$version-$page'),
      load: () => ref.read(apiProvider).get('/journals?page=$page'),
      builder: (data, reload) {
        final rows = items(data);
        return PageBody(
          children: [
            const Heading(
              'Jurnal Harianku',
              'Isi jurnal hanya untukmu. Analisis AI selalu memerlukan izinmu.',
            ),
            const SoftLabel('Privat • Hanya Aku', icon: Icons.lock_outline),
            const SizedBox(height: 20),
            CareCard(
              color: lavenderSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(
                    'Untuk Kamu, Nanti',
                    icon: Icons.mail_outline,
                  ),
                  const Text(
                    'Tulis pesan penyemangat yang bisa kamu buka kembali saat membutuhkannya.',
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => edit(null, true),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Tulis Surat untuk Diri Sendiri'),
                  ),
                ],
              ),
            ),
            SectionHeading(
              'Catatan Terakhir (${data['total'] ?? rows.length})',
              icon: Icons.edit_note,
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      SoftLabel(row['journal_date'], icon: Icons.lock_outline),
                      const SizedBox(height: 12),
                      Text(
                        row['content'],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => edit(row),
                ),
              ),
            if ((data['last_page'] as int? ?? 1) > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: page > 1 ? () => setState(() => page--) : null,
                    child: const Text('Sebelumnya'),
                  ),
                  Text('Halaman $page'),
                  TextButton(
                    onPressed: page < data['last_page']
                        ? () => setState(() => page++)
                        : null,
                    child: const Text('Berikutnya'),
                  ),
                ],
              ),
            const PrivacyNote(
              'Tidak ada kata yang salah dalam jurnalmu. Isi jurnal tidak dibagikan kepada kerabat. Analisis AI selalu memerlukan izinmu.',
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    ),
  );
}

class JournalEditor extends ConsumerStatefulWidget {
  const JournalEditor({super.key, this.entry, this.initialTitle = ''});
  final Json? entry;
  final String initialTitle;
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
    title.text = widget.entry?['title'] ?? widget.initialTitle;
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
        .watch(sessionProvider)
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
