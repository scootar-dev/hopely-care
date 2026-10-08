import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';

class CaregiverScreen extends ConsumerStatefulWidget {
  const CaregiverScreen({super.key});
  @override
  ConsumerState<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends ConsumerState<CaregiverScreen> {
  final token = TextEditingController();
  int version = 0;
  bool busy = false;
  Object? error;
  @override
  void dispose() {
    token.dispose();
    super.dispose();
  }

  Future<void> accept() async {
    setState(() => busy = true);
    try {
      await ref.read(apiProvider).post('/caregivers/accept', {
        'token': token.text.trim(),
      });
      token.clear();
      if (mounted) {
        setState(() => version++);
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
      title: const Text('Hopely • Pendamping'),
      actions: [
        IconButton(
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.person_outline),
          tooltip: 'Profil',
        ),
      ],
    ),
    body: DataPage(
      key: ValueKey(version),
      load: () => ref.read(apiProvider).get('/caregiver/patients'),
      builder: (data, reload) => PageBody(
        children: [
          const Heading(
            'Hadir, tanpa memaksa',
            'Dukungan kecil dapat berarti. Hormati ruang pribadi orang yang kamu dampingi.',
          ),
          CareCard(
            child: Column(
              children: [
                TextField(
                  controller: token,
                  decoration: const InputDecoration(
                    labelText: 'Kode undangan pribadi',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : accept,
                  child: const Text('Terima undangan'),
                ),
              ],
            ),
          ),
          if (error != null) ErrorNotice(error!),
          for (final patient in items(data))
            CareCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(patient['name'] ?? 'Pasien'),
                subtitle: Text(patient['relationship_label']),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push('/caregiver/${patient['patient_id']}'),
              ),
            ),
        ],
      ),
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
    appBar: AppBar(title: const Text('Ruang Pendamping')),
    body: DataPage(
      load: () => ref
          .read(apiProvider)
          .get('/caregiver/patients/${widget.patientId}/summary'),
      builder: (data, reload) => PageBody(
        children: [
          const Heading(
            'Ringkasan yang dibagikan',
            'Izin dapat berubah kapan saja. Jurnal dan percakapan AI tidak ditampilkan.',
          ),
          if (data['wellbeing_summary'] != null)
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Wellbeing • rata-rata laporan mandiri'),
                  for (final e in (data['wellbeing_summary'] as Json).entries)
                    Text('${e.key}: ${e.value ?? 'Belum tercatat'}'),
                ],
              ),
            ),
          if (data['symptom_summary'] != null)
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keluhan • rata-rata laporan mandiri'),
                  for (final e in (data['symptom_summary'] as Json).entries)
                    Text('${e.key}: ${e.value ?? 'Belum tercatat'}'),
                ],
              ),
            ),
          if (data['treatment_schedule'] != null)
            for (final t in data['treatment_schedule'] as List)
              CareCard(
                child: Text('${t['treatment_type']} • ${t['scheduled_at']}'),
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
            child: Column(
              children: [
                Text(
                  'Caregiver AI Coach',
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
