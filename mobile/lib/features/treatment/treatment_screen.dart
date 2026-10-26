import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';
import '../../core/theme/theme.dart';
import '../../core/notifications/treatment_reminders.dart';
import '../../core/notifications/reminder_host.dart';

class TreatmentScreen extends ConsumerStatefulWidget {
  const TreatmentScreen({super.key});
  @override
  ConsumerState<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends ConsumerState<TreatmentScreen> {
  int version = 0, page = 1;

  @override
  Widget build(BuildContext context) => DataPage(
    key: ValueKey('$version:$page'),
    load: () => ref.read(apiProvider).get('/treatments?page=$page'),
    builder: (data, reload) {
      final rows = items(data)
        ..sort(
          (a, b) => (a['scheduled_at'] as String).compareTo(
            b['scheduled_at'] as String,
          ),
        );
      return PageBody(
        children: [
          const SoftLabel('Ruang Teduh Perawatan', icon: Icons.spa_outlined),
          const SizedBox(height: 10),
          Text(
            'Perjalanan Perawatan',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          const Text('Siklus perawatanmu, satu langkah dalam satu waktu.'),
          TextButton.icon(
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Aktifkan pengingat jadwal di HP'),
            onPressed: () async {
              String message;
              try {
                final enabled = await TreatmentReminders.instance.enable();
                if (!context.mounted) return;
                await TreatmentReminders.instance.refresh(
                  ref.read(apiProvider),
                );
                message = enabled
                    ? 'Pengingat diaktifkan. Izinkan alarm tepat waktu di pengaturan HP agar sesuai jam jadwal.'
                    : 'Izinkan notifikasi Hopely Care di pengaturan HP untuk menerima pengingat.';
              } catch (_) {
                message =
                    'Pengingat belum dapat diaktifkan. Periksa koneksi dan izin perangkat.';
              }
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            },
          ),
          if (ref.watch(reminderErrorProvider) case final String message)
            Text(message, style: const TextStyle(color: mutedInk)),
          const SizedBox(height: 16),
          CareCard(
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Progres halaman ini')),
                    Text(
                      '${(rows.where((t) => t['status'] == 'completed').length / (rows.isEmpty ? 1 : rows.length) * 100).round()}% Selesai',
                      style: const TextStyle(
                        color: hopelyBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: rows.isEmpty
                      ? 0
                      : rows.where((t) => t['status'] == 'completed').length /
                            rows.length,
                  minHeight: 8,
                  backgroundColor: surfaceHighest,
                  color: hopelyBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 10),
                Text(
                  rows.isEmpty
                      ? 'Belum ada jadwal yang tercatat.'
                      : '${rows.length} catatan perawatan tersimpan',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              await context.push('/treatment/new');
              if (mounted) setState(() => version++);
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Jadwal / Catatan Dokter'),
          ),
          const SizedBox(height: 8),
          const SectionHeading('Agenda Perawatan'),
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
          if (rows.isEmpty)
            const CareCard(
              child: Text(
                'Belum ada jadwal. Tambahkan jika kamu ingin mencatatnya.',
              ),
            ),
          for (final t in rows)
            CareCard(
              padding: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.event_outlined,
                        size: 18,
                        color: hopelyBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          DateTime.parse(
                            t['scheduled_at'],
                          ).toLocal().toString().substring(0, 16),
                          style: const TextStyle(
                            color: hopelyBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SoftLabel(
                        t['status'] == 'completed' ? 'Selesai' : 'Terjadwal',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t['title'],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (t['location']?.toString().isNotEmpty == true)
                    Text(
                      t['location'],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  Text(t['treatment_type'] ?? 'Catatan perawatan'),
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
                    onPressed: () async {
                      await context.push('/treatment/${t['id']}');
                      if (mounted) setState(() => version++);
                    },
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
        var message = 'Jadwal tersimpan.';
        try {
          await TreatmentReminders.instance.clear();
          final enabled =
              status == 'scheduled' && scheduled.isAfter(DateTime.now())
              ? await TreatmentReminders.instance.enable()
              : true;
          if (!mounted) return;
          await TreatmentReminders.instance.refresh(ref.read(apiProvider));
          if (!enabled) {
            message +=
                ' Izinkan notifikasi di pengaturan HP untuk menerima pengingat.';
          }
        } catch (_) {
          message +=
              ' Pengingat belum tersinkron. Aktifkan kembali dari halaman Perjalanan.';
        }
        if (!mounted) return;
        ref.read(reminderRevisionProvider.notifier).state++;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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
