import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});
  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  final concerns = TextEditingController();
  @override
  void dispose() {
    concerns.dispose();
    super.dispose();
  }

  int days = 14;
  Json? report;
  bool busy = false;
  Object? error;
  Future<void> generate() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r =
          await ref.read(apiProvider).post('/doctor-summary', {
                'days': days,
                'reported_concerns': concerns.text
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .take(5)
                    .toList(),
              })
              as Json;
      if (mounted) {
        setState(() => report = r);
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

  List<String> lines() {
    final r = report!;
    final wellbeing = r['wellbeing'] as Json;
    return [
      'Periode: ${r['period']}',
      'Hari tercatat: ${r['recorded_days']}',
      for (final e in wellbeing.entries)
        '${e.key}: rata-rata ${e.value['mean'] ?? '-'} / 5; arah ${e.value['direction']}',
      for (final p in r['symptom_patterns'] as List)
        '${p['metric']}: ${p['mean']} / 5 (${p['record_count']} catatan)',
      for (final t in r['treatment_context'] as List)
        'Perawatan tercatat: ${t['treatment_type']} - ${t['scheduled_at']}',
      'Hal yang ingin disampaikan:',
      ...(r['reported_concerns'] as List).map((s) => s.toString()),
      'Pertanyaan untuk didiskusikan:',
      ...(r['questions_patient_may_want_to_discuss'] as List).map(
        (q) => q.toString(),
      ),
      r['disclaimer'] as String,
    ];
  }

  Future<void> export() async {
    try {
      final font = pw.Font.ttf(
        await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
      );
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: font, bold: font),
      );
      pdf.addPage(
        pw.MultiPage(
          build: (_) => [
            pw.Header(
              level: 0,
              child: pw.Text('Hopely Care - Ringkasan Konsultasi'),
            ),
            if (report!['metadata']['mode'] == 'mock')
              pw.Paragraph(text: 'DEMO OFFLINE - bukan hasil AI nyata'),
            ...lines().map((l) => pw.Paragraph(text: l)),
          ],
        ),
      );
      await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
        name: 'Hopely-Ringkasan.pdf',
      );
    } catch (e) {
      if (mounted) {
        setState(() => error = e);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ringkasan Konsultasi')),
    body: PageBody(
      children: [
        const Heading(
          'Bawa ceritamu ke konsultasi',
          'Ringkasan laporan mandiri untuk membantu percakapan dengan dokter.',
        ),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7 Hari')),
            ButtonSegment(value: 14, label: Text('14 Hari')),
            ButtonSegment(value: 30, label: Text('30 Hari')),
          ],
          selected: {days},
          onSelectionChanged: busy
              ? null
              : (v) => setState(() => days = v.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: concerns,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Yang ingin disampaikan (opsional)',
            helperText:
                'Satu hal per baris, maksimal 5. Akan disertakan pada PDF.',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy ? null : generate,
          child: Text(busy ? 'Menyiapkan ringkasan…' : 'Buat ringkasan'),
        ),
        const SizedBox(height: 24),
        if (error != null) ErrorNotice(error!),
        if (report != null) ...[
          MockNotice(report!['metadata']),
          for (final line in lines()) CareCard(child: Text(line)),
          FilledButton.icon(
            onPressed: export,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Pratinjau / simpan PDF'),
          ),
        ],
      ],
    ),
  );
}
