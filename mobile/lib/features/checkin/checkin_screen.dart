import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';
import '../../core/theme/theme.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key, this.symptoms = false, this.entry});
  final Json? entry;
  final bool symptoms;
  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final note = TextEditingController();
  late Map<String, int> scores;
  String? id;
  bool analysis = false, busy = false, loading = true, loadFailed = false;
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
    setState(() {
      loading = true;
      error = null;
      loadFailed = false;
    });
    try {
      if (widget.entry != null) {
        final row = widget.entry!;
        id = row['id'];
        for (final k in scores.keys.toList()) {
          scores[k] = (row[widget.symptoms ? k : '${k}_score'] as num).toInt();
        }
        note.text = row['optional_note'] ?? '';
        analysis = row['ai_analysis_allowed'] == true;
      } else if (!widget.symptoms) {
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
      loadFailed = true;
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
              'logged_at':
                  widget.entry?['logged_at'] ??
                  DateTime.now().toUtc().toIso8601String(),
              ...scores,
              'optional_note': note.text.trim(),
            }
          : {
              ...Checkin(
                date: widget.entry?['checkin_date'] ?? dateOnly(DateTime.now()),
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
        if (widget.entry != null) {
          Navigator.of(context).pop(true);
          return;
        }
        context.pushReplacement('/checkin/saved');
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
    const subtitles = {
      'mood': 'Suasana Hati',
      'anxiety': 'Tingkat Kecemasan',
      'energy': 'Stamina & Kelelahan',
      'sleep': 'Kualitas Istirahat',
      'pain': 'Rasa Sakit Tubuh',
      'fatigue': 'Rasa Lelah',
      'nausea': 'Rasa Mual',
      'dizziness': 'Rasa Pusing',
      'appetite': 'Nafsu Makan',
      'sleep_quality': 'Kualitas Istirahat',
    };
    final allowAI = ref
        .watch(sessionProvider)
        .consents
        .contains('AI_JOURNAL_ANALYSIS');
    return Scaffold(
      appBar: AppBar(
        leading: const BackHomeButton(),
        title: Text(widget.symptoms ? 'Catat Gejala' : 'Daily Check In'),
        actions: [
          IconButton(
            tooltip: 'Tutup',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : loadFailed
          ? PageBody(
              children: [
                ErrorNotice(error!),
                FilledButton(onPressed: load, child: const Text('Coba lagi')),
              ],
            )
          : PageBody(
              children: [
                Heading(
                  widget.symptoms
                      ? 'Dengarkan tubuhmu'
                      : 'Bagaimana keadaanmu?',
                  'Pilih skala 1 hingga 5 yang paling mewakili kondisimu saat ini.',
                ),
                for (final k in scores.keys)
                  MetricSelector(
                    label: widget.symptoms ? labels[k]! : _metricTitle(k),
                    subtitle: subtitles[k],
                    mood: k == 'mood',
                    icon:
                        const {
                          'mood': Icons.sentiment_satisfied_outlined,
                          'anxiety': Icons.psychology_outlined,
                          'energy': Icons.bolt_outlined,
                          'sleep': Icons.nightlight_outlined,
                          'pain': Icons.healing_outlined,
                        }[k] ??
                        Icons.monitor_heart_outlined,
                    value: scores[k]!,
                    highIsGood: [
                      'mood',
                      'energy',
                      'sleep',
                      'appetite',
                      'sleep_quality',
                    ].contains(k),
                    valueLabel: (value) => _metricValue(k, value),
                    lowLabel: _metricLowLabel(k),
                    highLabel: _metricHighLabel(k),
                    onChanged: (v) => setState(() => scores[k] = v),
                  ),
                CareCard(
                  padding: 16,
                  radius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: note,
                        maxLines: 4,
                        maxLength: 4000,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.edit_note),
                          labelText: 'Tambahkan catatan (opsional)',
                          hintText:
                              'Tuliskan keluhan atau hal yang membuatmu merasa lebih baik...',
                          filled: true,
                          fillColor: skySoft,
                        ),
                      ),
                      if (!widget.symptoms) ...[
                        const Divider(height: 24),
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
                    ],
                  ),
                ),
                const CareCard(
                  color: skySoft,
                  child: Text(
                    'Catatanmu bersifat pribadi. Ringkasan hanya dapat dibagikan sesuai pengaturan izinmu.',
                  ),
                ),
                if (error != null) ErrorNotice(error!),
                FilledButton.icon(
                  onPressed: busy ? null : save,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(busy ? 'Menyimpan...' : 'Simpan Ringkasan'),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  String _metricTitle(String key) => const {
    'mood': 'Mood',
    'anxiety': 'Cemas',
    'energy': 'Energi',
    'sleep': 'Tidur',
    'pain': 'Nyeri Fisik',
  }[key]!;

  String _metricValue(String key, int value) {
    final values = const {
      'mood': ['Sangat Murung', 'Murung', 'Biasa', 'Nyaman', 'Sangat Nyaman'],
      'anxiety': [
        'Sangat Tenang',
        'Cukup Tenang',
        'Sedang',
        'Cemas',
        'Sangat Cemas',
      ],
      'energy': ['Sangat Lemah', 'Lemah', 'Cukup', 'Baik', 'Penuh Energi'],
      'sleep': [
        'Buruk / Sulit',
        'Kurang Nyenyak',
        'Cukup Nyenyak',
        'Nyenyak',
        'Sangat Nyenyak',
      ],
      'pain': ['Tanpa Nyeri', 'Ringan', 'Sedang', 'Cukup Sakit', 'Nyeri Berat'],
    }[key];
    return '${values == null ? '$value / 5' : values[value - 1]} ($value)';
  }

  String _metricLowLabel(String key) =>
      (const {
        'mood': '1: Sangat Murung',
        'anxiety': '1: Sangat Tenang',
        'energy': '1: Sangat Lemah',
        'sleep': '1: Buruk / Sulit',
        'pain': '1: Tanpa Nyeri',
      }[key] ??
      '1: Rendah');

  String _metricHighLabel(String key) =>
      (const {
        'mood': '5: Sangat Nyaman',
        'anxiety': '5: Sangat Cemas',
        'energy': '5: Penuh Energi',
        'sleep': '5: Nyenyak',
        'pain': '5: Nyeri Berat',
      }[key] ??
      '5: Tinggi');
}

class CheckinSavedScreen extends StatelessWidget {
  const CheckinSavedScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(),
      title: const Text('Catatan Tersimpan'),
    ),
    body: PageBody(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: surfaceContainer,
            child: Icon(Icons.check_rounded, size: 36, color: hopelyBlue),
          ),
        ),
        const Heading(
          'Terima kasih sudah check-in.',
          'Catatanmu telah tersimpan. Tidak perlu memaksakan langkah berikutnya.',
        ),
        CareCard(
          radius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  IconWell(Icons.air, size: 48, radius: 12),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REKOMENDASI LEMBUT',
                          style: TextStyle(
                            fontSize: 12,
                            color: hopelyBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Latihan Napas 3 Menit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Pemberhentian sejenak untuk melonggarkan ketegangan.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/activities'),
                  child: const Text('Coba sekarang  →'),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.go('/home'),
          child: const Text('Kembali ke Beranda'),
        ),
        const ActionLink(
          'Lihat pola catatanku',
          '/insights',
          icon: Icons.show_chart,
        ),
        const ActionLink(
          'Lanjut menulis jurnal',
          '/journal',
          icon: Icons.edit_note,
        ),
      ],
    ),
  );
}
