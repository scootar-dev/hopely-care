import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';

String metricLabel(String key) =>
    const {
      'mood': 'Suasana hati',
      'anxiety': 'Kecemasan',
      'energy': 'Energi',
      'sleep': 'Kualitas tidur',
      'pain': 'Nyeri',
      'fatigue': 'Kelelahan',
      'nausea': 'Mual',
      'dizziness': 'Pusing',
      'appetite': 'Nafsu makan',
      'sleep_quality': 'Kualitas tidur',
    }[key] ??
    key.replaceAll('_', ' ');

String directionLabel(dynamic value) =>
    const {
      'increasing': 'Meningkat',
      'declining': 'Menurun',
      'stable': 'Relatif stabil',
      'improving': 'Membaik',
      'worsening': 'Perlu diperhatikan',
      'mixed': 'Pola beragam',
      'insufficient_data': 'Belum cukup data',
    }[value] ??
    'Belum cukup data';

String scoreLabel(dynamic value) =>
    value is num ? '${value.toStringAsFixed(1)} / 5' : 'Belum tercatat';

String reportDate(dynamic value, {bool time = false}) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return 'Belum tercatat';
  return DateFormat(
    time ? 'dd/MM/yyyy HH:mm' : 'dd/MM/yyyy',
  ).format(date.toLocal());
}

List<(String, List<String>)> summarySections(Json report) {
  final wellbeing = report['wellbeing'] as Map? ?? {};
  final period =
      report['period']?.toString().replaceAllMapped(
        RegExp(r'\d{4}-\d{2}-\d{2}'),
        (m) => reportDate(m[0]),
      ) ??
      '${reportDate(report['period_start'])} - ${reportDate(report['period_end'])}';
  List<String> entries(String key) => (report[key] as List? ?? [])
      .map((v) => v.toString())
      .where((v) => v.trim().isNotEmpty)
      .toList();
  return [
    (
      'Periode catatan',
      [period, '${report['recorded_days'] ?? 0} hari tercatat'],
    ),
    (
      'Kesejahteraan harian',
      [
        for (final entry in wellbeing.entries)
          '${metricLabel(entry.key.toString())}: ${scoreLabel(entry.value['mean'])}\n${directionLabel(entry.value['direction'])}',
        if (wellbeing.isEmpty)
          'Belum ada catatan kesejahteraan pada periode ini.',
      ],
    ),
    (
      'Keluhan fisik',
      [
        for (final pattern in report['symptom_patterns'] as List? ?? [])
          '${metricLabel(pattern['metric'].toString())}: ${scoreLabel(pattern['mean'])} (${pattern['record_count'] ?? 0} catatan)',
        if ((report['symptom_patterns'] as List? ?? []).isEmpty)
          'Belum ada keluhan fisik yang dicatat pada periode ini.',
      ],
    ),
    (
      'Jadwal perawatan',
      [
        for (final treatment in report['treatment_context'] as List? ?? [])
          '${treatment['treatment_type']}\n${reportDate(treatment['scheduled_at'], time: true)}',
        if ((report['treatment_context'] as List? ?? []).isEmpty)
          'Tidak ada jadwal perawatan pada ringkasan ini.',
      ],
    ),
    (
      'Hal yang ingin disampaikan',
      entries('reported_concerns').isEmpty
          ? ['Belum ada hal tambahan yang ditulis.']
          : entries('reported_concerns'),
    ),
    (
      'Pertanyaan untuk tim perawatan',
      entries('questions_patient_may_want_to_discuss').isEmpty
          ? ['Belum ada pertanyaan tambahan.']
          : entries('questions_patient_may_want_to_discuss'),
    ),
    (
      'Catatan penting',
      [
        report['disclaimer']?.toString() ??
            'Ringkasan berasal dari laporan mandiri dan bukan diagnosis.',
      ],
    ),
  ];
}

class SummaryReport extends StatelessWidget {
  const SummaryReport(this.report, {super.key});
  final Json report;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MockNotice(report['metadata']),
      if (report['metadata']?['fallback'] == 'ai_narrative_unavailable')
        const Text('AI belum dapat menyusun pertanyaan. Ringkasan ini hanya berisi statistik catatanmu.'),
      for (final section in summarySections(report))
        CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.$1, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              for (var index = 0; index < section.$2.length; index++) ...[
                if (index > 0) const Divider(height: 24),
                Text(section.$2[index], style: const TextStyle(height: 1.6)),
              ],
            ],
          ),
        ),
    ],
  );
}

class MetricSummaryTile extends StatelessWidget {
  const MetricSummaryTile(this.name, this.metric, {super.key});
  final String name;
  final Map metric;
  @override
  Widget build(BuildContext context) => CareCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(metricLabel(name), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              scoreLabel(metric['mean']),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(directionLabel(metric['direction'])),
          ],
        ),
      ],
    ),
  );
}
