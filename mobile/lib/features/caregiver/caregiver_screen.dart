import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';
import '../../core/theme/theme.dart';

class CaregiverScreen extends ConsumerWidget {
  const CaregiverScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      centerTitle: false,
      leading: const Padding(padding: EdgeInsets.all(10), child: HopelyMark()),
      title: const Text('Hopely Care'),
      actions: [
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: const Icon(Icons.notifications_none),
          tooltip: 'Notifikasi',
        ),
        IconButton(
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.person_outline),
          tooltip: 'Profil',
        ),
      ],
    ),
    body: DataPage(
      load: () async => {
        'patients': await ref.read(apiProvider).get('/caregiver/patients'),
        'notifications': await ref.read(apiProvider).get('/notifications'),
      },
      builder: (data, reload) {
        final patients = items(data['patients']);
        final alerts = items(data['notifications']).where(
          (n) =>
              n['notification_type'] == 'support_alert' && n['read_at'] == null,
        );
        return PageBody(
          children: [
            const SoftLabel('Mode Kerabat Aktif', icon: Icons.people_outline),
            const SizedBox(height: 20),
            const Heading(
              'Dashboard Kerabat',
              'Hadir dengan lembut, sambil menghormati ruang pribadi orang yang kamu dampingi.',
            ),
            for (final alert in alerts)
              CareCard(
                color: warningSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengingat dukungan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Luangkan waktu untuk menyapa orang yang kamu dampingi.',
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/caregiver/alerts/${alert['id']}'),
                      icon: const Icon(Icons.favorite_outline),
                      label: const Text('Lihat pengingat'),
                    ),
                  ],
                ),
              ),
            if (patients.isEmpty)
              const CareCard(
                child: Text(
                  'Belum ada pasien yang terhubung. Terima undangan pribadi dari orang yang akan kamu dampingi.',
                ),
              ),
            for (final patient in patients)
              CareCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: lavender,
                    child: Icon(Icons.person_outline, color: hopelyBlue),
                  ),
                  title: Text(patient['name'] ?? 'Pasien'),
                  subtitle: Text(patient['relationship_label']),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('/caregiver/${patient['patient_id']}'),
                ),
              ),
            FilledButton.icon(
              onPressed: () async {
                await context.push('/caregiver/connect');
                reload();
              },
              icon: const Icon(Icons.link),
              label: const Text('Hubungkan dengan Pasien'),
            ),
            const SizedBox(height: 22),
            const PrivacyNote(
              'Data yang tersedia mengikuti persetujuan dan izin pasien. Isi jurnal dan percakapan AI tidak dibagikan.',
            ),
          ],
        );
      },
    ),
  );
}

class CaregiverConnectScreen extends ConsumerStatefulWidget {
  const CaregiverConnectScreen({super.key});
  @override
  ConsumerState<CaregiverConnectScreen> createState() =>
      _CaregiverConnectScreenState();
}

class _CaregiverConnectScreenState
    extends ConsumerState<CaregiverConnectScreen> {
  final token = TextEditingController();
  bool busy = false;
  Object? error;
  @override
  void dispose() {
    token.dispose();
    super.dispose();
  }

  Future<void> accept() async {
    if (token.text.trim().isEmpty) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(apiProvider).post('/caregivers/accept', {
        'token': token.text.trim(),
      });
      if (mounted) {
        context.go('/caregiver');
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
      leading: const BackHomeButton(fallback: '/caregiver'),
      title: const Text('Pendamping & Keluarga'),
    ),
    body: PageBody(
      children: [
        const CareHero(compact: true),
        const Heading(
          'Terhubung sebagai Kerabat',
          'Masukkan kode undangan dari pasien untuk mulai mendampingi.',
        ),
        const CareCard(
          color: skySoft,
          child: Text(
            'Hadirkan rasa nyaman tanpa mengambil alih ruang pribadi orang terdekatmu.',
          ),
        ),
        CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading(
                'Kode Undangan Pasien',
                icon: Icons.key_outlined,
              ),
              TextField(
                controller: token,
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Tempel kode undangan',
                  helperText: 'Gunakan email akun yang diundang pasien.',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : accept,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(busy ? 'Menghubungkan…' : 'Hubungkan Sekarang'),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ErrorNotice(error!),
        const PrivacyNote(
          'Kode berlaku 48 jam dan hanya dapat dipakai sekali. Belum punya kode? Minta pasien membuka Profil → Undang Kerabat.',
        ),
        const SectionHeading('Kenapa perlu terhubung?'),
        const CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pahami ringkasan yang dibagikan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'Pasien memilih jenis ringkasan wellbeing, keluhan, jadwal, dan aktivitas yang dapat kamu lihat.',
              ),
              SizedBox(height: 18),
              Text(
                'Belajar menawarkan dukungan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'AI Coach membantu menyiapkan komunikasi yang hangat, tanpa menggantikan tim perawatan.',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class CaregiverPatientScreen extends ConsumerStatefulWidget {
  const CaregiverPatientScreen({super.key, required this.patientId});
  final String patientId;
  @override
  ConsumerState<CaregiverPatientScreen> createState() =>
      _CaregiverPatientScreenState();
}

class _CaregiverPatientScreenState
    extends ConsumerState<CaregiverPatientScreen> {
  final message = TextEditingController();
  Json? coach;
  Object? error;
  bool busy = false;
  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  Future<void> ask() async {
    if (message.text.trim().isEmpty) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data =
          await ref.read(apiProvider).post(
                '/caregiver/patients/${widget.patientId}/coach',
                {'message': message.text},
              )
              as Json;
      if (mounted) {
        setState(() => coach = data);
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
      leading: const BackHomeButton(fallback: '/caregiver'),
      title: const Text('Dashboard Kerabat'),
    ),
    body: DataPage(
      load: () => ref
          .read(apiProvider)
          .get('/caregiver/patients/${widget.patientId}/summary'),
      builder: (data, reload) => PageBody(
        children: [
          const Heading(
            'Mendampingi dengan penuh kasih',
            'Izin dapat berubah kapan saja. Jurnal dan percakapan AI tidak ditampilkan.',
          ),
          if (data['wellbeing_summary'] != null)
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Wellbeing • rata-rata laporan mandiri'),
                  Text(
                    '${data['wellbeing_summary']['recorded_days']} hari tercatat dalam 7 hari terakhir',
                  ),
                  for (final e in const {
                    'mood': 'Suasana hati',
                    'anxiety': 'Kecemasan',
                    'energy': 'Energi',
                    'sleep': 'Kualitas tidur',
                  }.entries)
                    ScoreBar(e.value, data['wellbeing_summary'][e.key] as num?),
                ],
              ),
            ),
          if (data['symptom_summary'] != null)
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keluhan • rata-rata laporan mandiri'),
                  Text(
                    '${data['symptom_summary']['record_count']} catatan dalam 7 hari terakhir',
                  ),
                  for (final e in const {
                    'pain': 'Nyeri',
                    'fatigue': 'Kelelahan',
                    'nausea': 'Mual',
                    'dizziness': 'Pusing',
                    'appetite': 'Nafsu makan',
                    'sleep_quality': 'Kualitas tidur',
                  }.entries)
                    ScoreBar(e.value, data['symptom_summary'][e.key] as num?),
                ],
              ),
            ),
          if (data['treatment_schedule'] != null)
            for (final t in data['treatment_schedule'] as List)
              CareCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.calendar_month_outlined,
                    color: hopelyBlue,
                  ),
                  title: Text(t['treatment_type']),
                  subtitle: Text(
                    DateTime.parse(
                      t['scheduled_at'],
                    ).toLocal().toString().substring(0, 16),
                  ),
                ),
              ),
          if (data['activity_status'] != null)
            CareCard(
              child: Text(
                'Aktivitas selesai: ${data['activity_status']['completed_count']}',
              ),
            ),
          if (!(data['permissions'] as Json).values.any((v) => v == true))
            const CareCard(
              child: Text('Belum ada jenis ringkasan yang diizinkan.'),
            ),
          CareCard(
            color: skySoft,
            child: Column(
              children: [
                Text(
                  'Saran Komunikasi untuk Kerabat',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: message,
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    hintText: 'Bagaimana menawarkan dukungan dengan nyaman?',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : ask,
                  child: Text(
                    busy ? 'Menyiapkan dukungan…' : 'Minta saran komunikasi',
                  ),
                ),
              ],
            ),
          ),
          if (error != null) ErrorNotice(error!),
          if (coach != null) ...[
            MockNotice(coach!['metadata']),
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coach!['support_message']),
                  const SizedBox(height: 16),
                  Text(coach!['communication_tip']),
                  const SizedBox(height: 16),
                  Text(coach!['suggested_action']),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
