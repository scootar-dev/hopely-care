import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';

class CareCircleScreen extends ConsumerStatefulWidget {
  const CareCircleScreen({super.key});
  @override
  ConsumerState<CareCircleScreen> createState() => _CareCircleScreenState();
}

class _CareCircleScreenState extends ConsumerState<CareCircleScreen> {
  final email = TextEditingController(), relationship = TextEditingController();
  int version = 0;
  bool busy = false;
  Object? error;
  Json? invitation;
  @override
  void dispose() {
    email.dispose();
    relationship.dispose();
    super.dispose();
  }

  Future<void> invite() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data =
          await ref.read(apiProvider).post('/caregivers/invite', {
                'email': email.text.trim(),
                'relationship_label': relationship.text.trim(),
              })
              as Json;
      if (mounted) {
        setState(() {
          invitation = data;
          version++;
        });
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
    appBar: AppBar(title: const Text('Lingkar Dukungan')),
    body: DataPage(
      key: ValueKey(version),
      load: () => ref.read(apiProvider).get('/caregivers'),
      builder: (data, reload) {
        final rows = items(data);
        return PageBody(
          children: [
            const Heading(
              'Kamu mengatur ruangmu',
              'Pendamping hanya melihat ringkasan yang kamu izinkan. Isi jurnal dan chat tetap pribadi.',
            ),
            const ActionLink('Atur persetujuan berbagi', '/privacy'),
            CareCard(
              child: Column(
                children: [
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email pendamping',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: relationship,
                    decoration: const InputDecoration(
                      labelText: 'Hubungan / panggilan',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy ? null : invite,
                    child: Text(busy ? 'Membuat undangan…' : 'Buat undangan'),
                  ),
                ],
              ),
            ),
            if (error != null) ErrorNotice(error!),
            if (invitation != null)
              CareCard(
                child: Column(
                  children: [
                    const Text(
                      'Berikan kode ini secara pribadi kepada pendamping. Berlaku 48 jam dan hanya dapat dipakai oleh email yang kamu undang.',
                    ),
                    const SizedBox(height: 8),
                    SelectableText(invitation!['invitation_token']),
                    TextButton.icon(
                      onPressed: () => Clipboard.setData(
                        ClipboardData(text: invitation!['invitation_token']),
                      ),
                      icon: const Icon(Icons.copy),
                      label: const Text('Salin kode'),
                    ),
                  ],
                ),
              ),
            for (final row in rows)
              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['relationship_label'],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${row['invited_email']} • ${row['invitation_status']}',
                    ),
                    for (final e in const {
                      'can_view_wellbeing_summary': 'Ringkasan wellbeing',
                      'can_view_symptom_summary': 'Ringkasan keluhan',
                      'can_view_treatment_schedule': 'Jadwal perawatan',
                      'can_view_activity_status': 'Status aktivitas',
                      'can_receive_support_alert': 'Pengingat dukungan',
                    }.entries)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.value),
                        value: row['permissions'][e.key] == true,
                        onChanged: (v) async {
                          try {
                            final p = Map<String, dynamic>.from(
                              row['permissions'],
                            );
                            final payload = <String, dynamic>{
                              for (final k in p.keys.where(
                                (k) => k.startsWith('can_'),
                              ))
                                k: p[k],
                            };
                            payload[e.key] = v;
                            await ref
                                .read(apiProvider)
                                .put(
                                  '/caregivers/${row['id']}/permissions',
                                  payload,
                                );
                            reload();
                          } catch (e) {
                            if (mounted) {
                              setState(() => error = e);
                            }
                          }
                        },
                      ),
                    if (row['invitation_status'] != 'revoked')
                      TextButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(apiProvider)
                                .delete('/caregivers/${row['id']}');
                            reload();
                          } catch (e) {
                            if (mounted) {
                              setState(() => error = e);
                            }
                          }
                        },
                        child: const Text('Cabut akses pendamping'),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}
