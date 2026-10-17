import '../doctor_summary/summary_report.dart';
import '../../core/notifications/treatment_reminders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api.dart';
import '../../core/notifications/push_service.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/stitch.dart';
import '../../core/widgets/ui.dart';
import '../journal/journal_screen.dart';
import '../treatment/treatment_screen.dart';
import '../activities/activities_screen.dart';

Json _record(dynamic value) {
  if (value is Map && value['items'] is List) {
    final rows = items(value);
    if (rows.isNotEmpty) {
      return rows.first;
    }
  }
  return Map<String, dynamic>.from(value as Map);
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<Json> _load(WidgetRef ref) async {
    final api = ref.read(apiProvider);
    final result = await Future.wait([
      api.get('/checkins'),
      api.get('/symptoms'),
    ]);
    return {'checkins': items(result[0]), 'symptoms': items(result[1])};
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(),
      title: const Text('Riwayat Tracking'),
      actions: const [
        Padding(padding: EdgeInsets.all(10), child: HopelyMark()),
      ],
    ),
    body: DataPage(
      load: () => _load(ref),
      builder: (value, reload) {
        final data = value as Json;
        final checkins = data['checkins'] as List<Json>;
        final symptoms = data['symptoms'] as List<Json>;
        return PageBody(
          children: [
            const Heading(
              'Riwayat tracking',
              'Lihat kembali catatan wellbeing dan gejala yang kamu simpan.',
              badge: 'CATATAN PRIBADI',
            ),
            if (checkins.isEmpty && symptoms.isEmpty)
              const CareCard(
                child: Text(
                  'Belum ada riwayat. Catatan baru akan muncul di sini.',
                ),
              ),
            if (checkins.isNotEmpty) ...[
              const SectionHeading(
                'Check-in harian',
                icon: Icons.favorite_outline,
              ),
              for (final row in checkins)
                CareCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const IconWell(Icons.sentiment_satisfied_outlined),
                    title: Text(row['checkin_date'].toString()),
                    subtitle: Text(
                      'Mood ${row['mood_score']}  |  Cemas ${row['anxiety_score']}  |  Energi ${row['energy_score']}\n'
                      'Tidur ${row['sleep_score']}  |  Nyeri ${row['pain_score']}',
                    ),
                  ),
                ),
            ],
            if (symptoms.isNotEmpty) ...[
              const SectionHeading(
                'Log gejala',
                icon: Icons.monitor_heart_outlined,
              ),
              for (final row in symptoms)
                CareCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const IconWell(Icons.monitor_heart_outlined),
                    title: Text(_dateTimeLabel(row['logged_at'])),
                    subtitle: Text(
                      'Nyeri ${row['pain']}  |  Lelah ${row['fatigue']}  |  Mual ${row['nausea']}\n'
                      'Pusing ${row['dizziness']}  |  Nafsu makan ${row['appetite']}  |  Tidur ${row['sleep_quality']}',
                    ),
                  ),
                ),
            ],
            const PrivacyNote(
              'Riwayat ini hanya milikmu dan tidak menjadi diagnosis. Bawa catatan yang relevan saat berkonsultasi.',
            ),
          ],
        );
      },
    ),
  );
}

String _dateTimeLabel(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  return date == null
      ? value.toString()
      : date.toLocal().toString().substring(0, 16);
}

class TreatmentDetailScreen extends ConsumerStatefulWidget {
  const TreatmentDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<TreatmentDetailScreen> createState() => _TreatmentDetailState();
}

class _TreatmentDetailState extends ConsumerState<TreatmentDetailScreen> {
  int version = 0;

  Future<void> edit(Json row) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => TreatmentEditor(entry: row)),
    );
    if (mounted) {
      setState(() => version++);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/treatment'),
      title: const Text('Detail Perawatan'),
    ),
    body: DataPage(
      key: ValueKey(version),
      load: () => ref.read(apiProvider).get('/treatments/${widget.id}'),
      builder: (value, reload) {
        final row = _record(value);
        return PageBody(
          children: [
            Heading(
              row['title']?.toString() ?? 'Detail perawatan',
              'Catatan jadwal dan informasi yang kamu simpan.',
              badge: row['status'] == 'completed' ? 'SELESAI' : 'TERJADWAL',
            ),
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SoftLabel(
                    'Jadwal',
                    icon: Icons.calendar_month_outlined,
                  ),
                  const SizedBox(height: 10),
                  Text(_dateTimeLabel(row['scheduled_at'])),
                  const SizedBox(height: 18),
                  const SoftLabel(
                    'Jenis perawatan',
                    icon: Icons.medical_services_outlined,
                  ),
                  const SizedBox(height: 10),
                  Text(row['treatment_type']?.toString() ?? '-'),
                  if (row['location']?.toString().isNotEmpty == true) ...[
                    const SizedBox(height: 18),
                    const SoftLabel('Lokasi', icon: Icons.place_outlined),
                    const SizedBox(height: 10),
                    Text(row['location'].toString()),
                  ],
                  if (row['notes']?.toString().isNotEmpty == true) ...[
                    const SizedBox(height: 18),
                    const SoftLabel('Catatan', icon: Icons.notes_outlined),
                    const SizedBox(height: 10),
                    Text(row['notes'].toString()),
                  ],
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => edit(row),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Ubah catatan'),
            ),
          ],
        );
      },
    ),
  );
}

class JournalReflectionScreen extends ConsumerStatefulWidget {
  const JournalReflectionScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<JournalReflectionScreen> createState() =>
      _JournalReflectionState();
}

class ActivityRouteScreen extends ConsumerWidget {
  const ActivityRouteScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DataPage(
    load: () => ref.read(apiProvider).get('/activities/recommended'),
    builder: (value, reload) {
      final rows = items(value);
      final matches = rows.where((row) => row['id'].toString() == id);
      if (matches.isEmpty) {
        return Scaffold(
          appBar: AppBar(
            leading: const BackHomeButton(fallback: '/activities'),
            title: const Text('Detail Aktivitas'),
          ),
          body: const PageBody(
            children: [
              CareCard(
                child: Text(
                  'Rekomendasi aktivitas ini sudah tidak tersedia. Muat ulang daftar aktivitas untuk mendapatkan rekomendasi terbaru.',
                ),
              ),
            ],
          ),
        );
      }
      return ActivityDetail(recommendation: matches.first);
    },
  );
}

class _JournalReflectionState extends ConsumerState<JournalReflectionScreen> {
  int version = 0;

  Future<Json> _load() async {
    final api = ref.read(apiProvider);
    final result = await Future.wait([
      api.get('/journals/${widget.id}'),
      api.get('/journals/${widget.id}/reflection'),
    ]);
    return {'journal': _record(result[0]), 'reflection': result[1] as Json};
  }

  Future<void> edit(Json journal) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => JournalEditor(entry: journal)),
    );
    if (mounted) {
      setState(() => version++);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/journal'),
      title: const Text('Refleksi Jurnal'),
    ),
    body: DataPage(
      key: ValueKey(version),
      load: _load,
      builder: (value, reload) {
        final data = value as Json;
        final journal = data['journal'] as Json;
        final reflection = data['reflection'] as Json;
        final available = reflection['available'] == true;
        final themes = ((reflection['themes'] as List?) ?? const [])
            .map((e) => e.toString())
            .join(', ');
        return PageBody(
          children: [
            Heading(
              journal['title']?.toString().isNotEmpty == true
                  ? journal['title'].toString()
                  : 'Catatan ${journal['journal_date']}',
              journal['journal_date']?.toString() ?? 'Jurnal pribadi',
              badge: 'PRIVAT',
            ),
            CareCard(
              color: lavenderSoft,
              child: Text(journal['content']?.toString() ?? ''),
            ),
            const SectionHeading(
              'Refleksi Hopely AI',
              icon: Icons.auto_awesome_outlined,
            ),
            if (available) ...[
              MockNotice({
                'mode':
                    reflection['model_version']?.toString().startsWith(
                          'mock',
                        ) ==
                        true
                    ? 'mock'
                    : 'live',
              }),
              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sinyal emosi: ${reflection['primary_emotion']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (themes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('Tema: $themes'),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Ini adalah refleksi berbasis catatan, bukan diagnosis.',
                    ),
                  ],
                ),
              ),
            ] else
              const CareCard(
                child: Text(
                  'Belum ada refleksi AI tersimpan untuk jurnal ini. Aktifkan izin analisis lalu simpan ulang jurnal untuk membuatnya.',
                ),
              ),
            FilledButton.icon(
              onPressed: () => edit(journal),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Ubah jurnal'),
            ),
          ],
        );
      },
    ),
  );
}

class InsightDetailScreen extends ConsumerWidget {
  const InsightDetailScreen({super.key, this.days = 14});
  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/insights'),
      title: const Text('Detail Insight'),
    ),
    body: DataPage(
      load: () => ref.read(apiProvider).get('/insights?days=$days'),
      builder: (value, reload) {
        final data = value as Json;
        final metrics = data['metrics'] as Json;
        final patterns = (data['contextual_patterns'] as List?) ?? const [];
        return PageBody(
          children: [
            const Heading(
              'Detail perjalanan emosimu',
              'Ringkasan ini membantu melihat pola, bukan menetapkan diagnosis.',
              badge: 'REFLEKSI PSIKO-ONKOLOGI',
            ),
            CareCard(
              color: skySoft,
              child: Text(
                '${data['recorded_days']} dari $days hari tercatat. Arah umum: ${directionLabel(data['overall_direction'])}.',
              ),
            ),
            for (final key in ['mood', 'anxiety', 'energy', 'sleep', 'pain'])
              MetricSummaryTile(key, metrics[key] as Map? ?? {}),
            if (patterns.isNotEmpty) ...[
              const SectionHeading(
                'Pola kontekstual',
                icon: Icons.insights_outlined,
              ),
              for (final pattern in patterns)
                CareCard(child: Text(pattern['observation'].toString())),
            ],
            const PrivacyNote(
              'Gunakan detail ini sebagai bahan percakapan dengan tenaga kesehatan. Data tetap berasal dari laporan mandiri.',
            ),
          ],
        );
      },
    ),
  );
}

class SavedSummaryScreen extends ConsumerWidget {
  const SavedSummaryScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/doctor-summary'),
      title: const Text('Ringkasan Tersimpan'),
    ),
    body: DataPage(
      load: () => ref.read(apiProvider).get('/doctor-summary/$id'),
      builder: (value, reload) {
        final report = value as Json;
        return PageBody(
          children: [
            Heading(
              'Ringkasan konsultasi',
              '${report['period_start']} - ${report['period_end']}',
              badge: 'ARSIP PRIBADI',
            ),
            SummaryReport(report),
            const PrivacyNote(
              'Ringkasan ini dibuat dari catatanmu dan tidak menggantikan penilaian tenaga kesehatan.',
            ),
          ],
        );
      },
    ),
  );
}

class KnowledgeArticleScreen extends StatelessWidget {
  const KnowledgeArticleScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/knowledge'),
      title: const Text('Detail Artikel'),
    ),
    body: PageBody(
      children: [
        const Heading(
          'Artikel terkurasi',
          'Detail artikel akan menampilkan naskah dan sumber yang sudah ditinjau.',
          badge: 'INFORMASI TEPERCAYA',
        ),
        CareCard(
          color: warningSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_book_outlined, color: hopelyBlue, size: 32),
              const SizedBox(height: 12),
              const Text(
                'Katalog artikel terkurasi belum tersedia pada server ini, jadi Hopely tidak menampilkan isi atau sumber fiktif.',
              ),
              const SizedBox(height: 8),
              Text('ID artikel: $id'),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => context.go('/knowledge'),
          icon: const Icon(Icons.search),
          label: const Text('Cari informasi tepercaya'),
        ),
      ],
    ),
  );
}

class TreatmentProfileScreen extends ConsumerStatefulWidget {
  const TreatmentProfileScreen({super.key});

  @override
  ConsumerState<TreatmentProfileScreen> createState() =>
      _TreatmentProfileState();
}

class _TreatmentProfileState extends ConsumerState<TreatmentProfileScreen> {
  final name = TextEditingController();
  final birthYear = TextEditingController();
  final cancerContext = TextEditingController();
  final treatmentPhase = TextEditingController();
  final timezone = TextEditingController();
  bool busy = false;
  Object? error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(sessionProvider).profile ?? {};
    name.text = profile['display_name']?.toString() ?? '';
    birthYear.text = profile['birth_year']?.toString() ?? '';
    cancerContext.text = profile['cancer_context']?.toString() ?? '';
    treatmentPhase.text = profile['treatment_phase']?.toString() ?? '';
    timezone.text = profile['timezone']?.toString() ?? 'Asia/Jakarta';
  }

  @override
  void dispose() {
    for (final controller in [
      name,
      birthYear,
      cancerContext,
      treatmentPhase,
      timezone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    final year = birthYear.text.trim();
    if (year.isNotEmpty && int.tryParse(year) == null) {
      setState(() => error = 'Tahun lahir harus berupa angka.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(apiProvider).put('/profile', {
        'display_name': name.text.trim(),
        'birth_year': year.isEmpty ? null : int.parse(year),
        'cancer_context': cancerContext.text.trim(),
        'treatment_phase': treatmentPhase.text.trim(),
        'timezone': timezone.text.trim(),
        'onboarding_completed': true,
      });
      await ref.read(sessionProvider).refresh();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/profile'),
      title: const Text('Profil Perawatan'),
    ),
    body: PageBody(
      children: [
        const Heading(
          'Konteks perjalananmu',
          'Simpan informasi yang membantu fitur Hopely memberi konteks yang lebih relevan.',
        ),
        TextField(
          controller: name,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'Nama panggilan'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: birthYear,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: 'Tahun lahir (opsional)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: cancerContext,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Konteks kesehatan (opsional)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: treatmentPhase,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: 'Fase perawatan (opsional)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: timezone,
          decoration: const InputDecoration(labelText: 'Zona waktu'),
        ),
        const SizedBox(height: 16),
        if (error != null) ErrorNotice(error!),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? 'Menyimpan...' : 'Simpan profil'),
        ),
      ],
    ),
  );
}

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsState();
}

class _NotificationSettingsState
    extends ConsumerState<NotificationSettingsScreen> {
  bool busy = false;
  Object? error;

  Future<void> enableDeviceReminders() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final api = ref.read(apiProvider);
      String message;
      if (api.session.caregiver) {
        await PushService.enable(api);
        message = 'Pengaturan notifikasi perangkat diperbarui.';
      } else {
        message = await enableTreatmentReminders(api);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/profile'),
      title: const Text('Pengaturan Notifikasi'),
    ),
    body: PageBody(
      children: [
        const Heading(
          'Notifikasi yang kamu kendalikan',
          'Pengingat hanya aktif setelah kamu memberi izin pada perangkat dan akun.',
        ),
        CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SoftLabel(
                'Pengingat perangkat',
                icon: Icons.notifications_active_outlined,
              ),
              const SizedBox(height: 12),
              const Text(
                'Aktifkan notifikasi untuk jadwal yang kamu simpan. Pengingat perjalanan di HP tetap tersedia saat aplikasi ditutup.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: busy ? null : enableDeviceReminders,
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(busy ? 'Mengaktifkan...' : 'Aktifkan pengingat'),
              ),
            ],
          ),
        ),
        if (error != null) ErrorNotice(error!),
        const CareCard(
          child: ActionLink(
            'Preferensi notifikasi komunitas',
            '/community/preferences',
            icon: Icons.forum_outlined,
          ),
        ),
        const CareCard(
          child: ActionLink(
            'Lihat kotak notifikasi',
            '/notifications',
            icon: Icons.inbox_outlined,
          ),
        ),
      ],
    ),
  );
}

class DataAccountScreen extends ConsumerWidget {
  const DataAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const BackHomeButton(fallback: '/profile'),
        title: const Text('Data & Akun'),
      ),
      body: PageBody(
        children: [
          const Heading(
            'Data dan akunmu',
            'Kelola akses, privasi, dan pilihan penghapusan data dari satu tempat.',
          ),
          CareCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SoftLabel(
                  'Akun aktif',
                  icon: Icons.account_circle_outlined,
                ),
                const SizedBox(height: 12),
                Text(
                  session.user?['email']?.toString() ??
                      'Email akun tersimpan aman.',
                ),
                const SizedBox(height: 8),
                Text('Peran: ${session.caregiver ? 'Pendamping' : 'Pasien'}'),
              ],
            ),
          ),
          const CareCard(
            child: ActionLink(
              'Privasi & persetujuan',
              '/privacy',
              icon: Icons.lock_outline,
            ),
          ),
          if (!session.caregiver)
            const CareCard(
              child: ActionLink(
                'Profil dan konteks perawatan',
                '/treatment-profile',
                icon: Icons.edit_note_outlined,
              ),
            ),
          const CareCard(
            child: ActionLink(
              'Hapus akun dan data',
              '/profile',
              icon: Icons.delete_outline,
            ),
          ),
          const PrivacyNote(
            'Keluar akun atau reset kata sandi dapat mencabut sesi. Penghapusan akun bersifat permanen dan dikonfirmasi dari halaman profil.',
          ),
        ],
      ),
    );
  }
}

class VoiceAssistantUnavailableScreen extends StatelessWidget {
  const VoiceAssistantUnavailableScreen({super.key, this.kind = 'voice'});
  final String kind;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/chat'),
      title: Text(kind == 'audio' ? 'Audio Hopely AI' : 'Mode Suara Hopely AI'),
    ),
    body: PageBody(
      children: [
        CareCard(
          color: warningSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mic_none_outlined, color: hopelyBlue, size: 42),
              const SizedBox(height: 12),
              Text(
                'Mode suara belum tersedia',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Build ini belum memasang layanan rekam, transkripsi, atau pemutaran suara. Hopely tidak akan mensimulasikan rekaman atau respons audio.',
              ),
            ],
          ),
        ),
        const PrivacyNote(
          'Percakapan teks Hopely AI tetap tersedia dengan izin AI Chat. Untuk kebutuhan klinis atau darurat, hubungi layanan yang sesuai.',
        ),
        FilledButton.icon(
          onPressed: () => context.go('/chat'),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Kembali ke percakapan teks'),
        ),
      ],
    ),
  );
}
