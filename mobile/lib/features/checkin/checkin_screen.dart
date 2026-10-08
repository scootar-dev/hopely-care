import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key, this.symptoms = false});
  final bool symptoms;
  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final note = TextEditingController();
  late Map<String, int> scores;
  String? id;
  bool analysis = false, busy = false, loading = true;
  Object? error;
  @override
  void initState() {
    super.initState();
    scores = {
      for (final k
          in widget.symptoms
              ? [
                  'pain',
                  'fatigue',
                  'nausea',
                  'dizziness',
                  'appetite',
                  'sleep_quality',
                ]
              : ['mood', 'anxiety', 'energy', 'sleep', 'pain'])
        k: 3,
    };
    load();
  }

  Future<void> load() async {
    try {
      if (!widget.symptoms) {
        final rows = items(await ref.read(apiProvider).get('/checkins'));
        final today = rows
            .where((c) => c['checkin_date'] == dateOnly(DateTime.now()))
            .firstOrNull;
        if (today != null) {
          id = today['id'];
          for (final k in scores.keys.toList()) {
            scores[k] = (today['${k}_score'] as num).toInt();
          }
          note.text = today['optional_note'] ?? '';
          analysis = today['ai_analysis_allowed'] == true;
        }
      }
    } catch (e) {
      error = e;
    }
    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final api = ref.read(apiProvider);
      final Json data = widget.symptoms
          ? {
              'logged_at': DateTime.now().toUtc().toIso8601String(),
              ...scores,
              'optional_note': note.text.trim(),
            }
          : {
              ...Checkin(
                date: dateOnly(DateTime.now()),
                scores: scores,
              ).toJson(),
              'optional_note': note.text.trim(),
              'ai_analysis_allowed':
                  analysis &&
                  ref
                      .read(sessionProvider)
                      .consents
                      .contains('AI_JOURNAL_ANALYSIS'),
            };
      final path = widget.symptoms ? '/symptoms' : '/checkins';
      final result = id == null
          ? await api.post(path, data)
          : await api.put('$path/$id', data);
      id = result['id'];
      if (!widget.symptoms &&
          analysis &&
          note.text.trim().isNotEmpty &&
          ref.read(sessionProvider).consents.contains('AI_JOURNAL_ANALYSIS')) {
        try {
          await api.post('/checkins/$id/analyze');
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Catatan tersimpan. Analisis AI belum tersedia.'),
              ),
            );
          }
        }
      }
      if (mounted) {
        context.pop();
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
  Widget build(BuildContext context) {
    const labels = {
      'mood': 'Suasana Hati',
      'anxiety': 'Tingkat Kecemasan',
      'energy': 'Energi Fisik',
      'sleep': 'Kualitas Tidur',
      'pain': 'Tingkat Nyeri',
      'fatigue': 'Kelelahan',
      'nausea': 'Mual',
      'dizziness': 'Pusing',
      'appetite': 'Nafsu Makan',
      'sleep_quality': 'Kualitas Tidur',
    };
    final allowAI = ref
        .read(sessionProvider)
        .consents
        .contains('AI_JOURNAL_ANALYSIS');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.symptoms ? 'Keluhan Fisik' : 'Check-In Emosional'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : PageBody(
              children: [
                Heading(
                  widget.symptoms ? 'Dengarkan tubuhmu' : 'Check-in Hari Ini',
                  'Kenali kondisi yang kamu rasakan, tanpa penilaian.',
                ),
                for (final k in scores.keys)
                  MetricSelector(
                    label: labels[k]!,
                    value: scores[k]!,
                    highIsGood: [
                      'mood',
                      'energy',
                      'sleep',
                      'appetite',
                      'sleep_quality',
                    ].contains(k),
                    onChanged: (v) => setState(() => scores[k] = v),
                  ),
                CareCard(
                  child: TextField(
                    controller: note,
                    maxLines: 4,
                    maxLength: 4000,
                    decoration: const InputDecoration(
                      labelText: 'Ada yang ingin kamu ceritakan?',
                      helperText: 'Opsional • catatan pribadi',
                    ),
                  ),
                ),
                if (!widget.symptoms)
                  CareCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Izinkan analisis AI untuk catatan ini',
                          ),
                          subtitle: Text(
                            allowAI
                                ? 'Hanya jika kamu nyaman.'
                                : 'Aktifkan izin analisis di Pengaturan Privasi terlebih dahulu.',
                          ),
                          value: analysis && allowAI,
                          onChanged: allowAI
                              ? (v) => setState(() => analysis = v)
                              : null,
                        ),
                        if (!allowAI)
                          const ActionLink('Pengaturan privasi', '/privacy'),
                      ],
                    ),
                  ),
                const CareCard(
                  color: Color(0xFFE4F6F1),
                  child: Text(
                    'Kamu telah meluangkan waktu untuk mendengarkan dirimu.',
                  ),
                ),
                if (error != null) ErrorNotice(error!),
                FilledButton(
                  onPressed: busy ? null : save,
                  child: Text(busy ? 'Menyimpan…' : 'Simpan & Lanjutkan'),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
