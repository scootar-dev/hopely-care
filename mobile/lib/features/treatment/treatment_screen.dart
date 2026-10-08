import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/theme/theme.dart';

class TreatmentScreen extends ConsumerStatefulWidget {
  const TreatmentScreen({super.key});
  @override
  ConsumerState<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends ConsumerState<TreatmentScreen> {
  int version = 0;
  Future<void> edit([Json? entry]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TreatmentEditor(entry: entry)),
    );
    if (mounted) {
      setState(() => version++);
    }
  }

  @override
  Widget build(BuildContext context) => DataPage(
    key: ValueKey(version),
    load: () => ref.read(apiProvider).get('/treatments'),
    builder: (data, reload) {
      final rows = items(data)
        ..sort(
          (a, b) => (a['scheduled_at'] as String).compareTo(
            b['scheduled_at'] as String,
          ),
        );
      return PageBody(
        children: [
          const Heading(
            'Perjalanan Perawatan',
            'Satu langkah, satu hari. Catat jadwal sesuai arahan tim perawatanmu.',
          ),
          FilledButton.icon(
            onPressed: edit,
            icon: const Icon(Icons.add),
            label: const Text('Tambah jadwal'),
          ),
          const SizedBox(height: 24),
          if (rows.isEmpty)
            const CareCard(
              child: Text(
                'Belum ada jadwal. Tambahkan jika kamu ingin mencatatnya.',
              ),
            ),
          for (final t in rows)
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['title'],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    DateTime.parse(
                      t['scheduled_at'],
                    ).toLocal().toString().substring(0, 16),
                  ),
                  Text('${t['treatment_type']} • ${t['status']}'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final offset in [-2, -1, 0, 1, 2])
                        Chip(
                          label: Text(
                            offset == 0
                                ? 'Hari perawatan'
                                : 'H${offset > 0 ? '+' : ''}$offset',
                          ),
                          backgroundColor: offset == 0
                              ? peach
                              : const Color(0xFFF0F4F1),
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => edit(t),
                    child: const Text('Lihat / ubah jadwal'),
                  ),
                ],
              ),
            ),
          const ActionLink(
            'Catat keluhan fisik',
            '/symptoms',
            icon: Icons.monitor_heart_outlined,
          ),
          const ActionLink(
            'Catatan pribadi',
            '/journal',
            icon: Icons.edit_note,
          ),
        ],
      );
    },
  );
}

class TreatmentEditor extends ConsumerStatefulWidget {
  const TreatmentEditor({super.key, this.entry});
  final Json? entry;
  @override
  ConsumerState<TreatmentEditor> createState() => _TreatmentEditorState();
}

class _TreatmentEditorState extends ConsumerState<TreatmentEditor> {
  final title = TextEditingController(),
      type = TextEditingController(),
      location = TextEditingController(),
      notes = TextEditingController();
  final form = GlobalKey<FormState>();
  late DateTime scheduled;
  String status = 'scheduled';
  bool busy = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    title.text = e?['title'] ?? '';
    type.text = e?['treatment_type'] ?? '';
    location.text = e?['location'] ?? '';
    notes.text = e?['notes'] ?? '';
    scheduled = e == null
        ? DateTime.now().add(const Duration(days: 1))
        : DateTime.parse(e['scheduled_at']).toLocal();
    status = e?['status'] ?? 'scheduled';
  }

  @override
  void dispose() {
    for (final c in [title, type, location, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: scheduled,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) {
      return;
    }
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(scheduled),
    );
    if (t != null && mounted) {
      setState(
        () => scheduled = DateTime(d.year, d.month, d.day, t.hour, t.minute),
      );
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = {
        'title': title.text,
        'treatment_type': type.text,
        'scheduled_at': scheduled.toUtc().toIso8601String(),
        'location': location.text,
        'notes': notes.text,
        'status': status,
      };
      if (widget.entry == null) {
        await ref.read(apiProvider).post('/treatments', data);
      } else {
        await ref
            .read(apiProvider)
            .put('/treatments/${widget.entry!['id']}', data);
      }
      if (mounted) {
        Navigator.pop(context);
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
    appBar: AppBar(title: const Text('Jadwal Perawatan')),
    body: PageBody(
      children: [
        Form(
          key: form,
          child: Column(
            children: [
              TextFormField(
                controller: title,
                maxLength: 150,
                decoration: const InputDecoration(labelText: 'Nama jadwal'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Isi nama jadwal' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: type,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Jenis perawatan'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Isi jenis perawatan' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(scheduled.toString().substring(0, 16)),
                leading: const Icon(Icons.calendar_month),
                trailing: const Icon(Icons.edit),
                onTap: pick,
              ),
              TextField(
                controller: location,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Lokasi (opsional)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notes,
                maxLines: 3,
                maxLength: 4000,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: status,
                items: const [
                  DropdownMenuItem(
                    value: 'scheduled',
                    child: Text('Terjadwal'),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Sudah dijalani'),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Dibatalkan'),
                  ),
                ],
                onChanged: (v) => setState(() => status = v!),
                decoration: const InputDecoration(labelText: 'Status catatan'),
              ),
            ],
          ),
        ),
        if (error != null) ErrorNotice(error!),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? 'Menyimpan…' : 'Simpan jadwal'),
        ),
      ],
    ),
  );
}
