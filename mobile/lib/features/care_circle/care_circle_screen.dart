import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';
import '../../core/theme/theme.dart';

class CareCircleScreen extends ConsumerStatefulWidget {
  const CareCircleScreen({super.key});
  @override
  ConsumerState<CareCircleScreen> createState() => _CareCircleScreenState();
}

class _CareCircleScreenState extends ConsumerState<CareCircleScreen> {
  final formKey = GlobalKey<FormState>();
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
    if (!formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
      invitation = null;
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
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/profile'),
      title: const Text('Undang Kerabat'),
    ),
    body: DataPage(
      key: ValueKey(version),
      load: () => ref.read(apiProvider).get('/caregivers'),
      builder: (data, reload) {
        final rows = items(data);
        return PageBody(
          children: [
            const Heading(
              'Dukungan dalam kendalimu',
              'Pendamping hanya melihat ringkasan yang kamu izinkan. Isi jurnal dan chat tetap pribadi.',
            ),
            const ActionLink('Atur persetujuan berbagi', '/privacy'),
            CareCard(
              child: Form(
                key: formKey,
                child: Column(
                children: [
                  const Text(
                    'Pendamping menerima undangan melalui akun Kerabat dengan email yang kamu masukkan. Setelah kode dibuat, salin dan kirimkan sendiri secara pribadi.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      final address = value?.trim().toLowerCase() ?? '';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(address)) {
                        return 'Masukkan email pendamping yang valid.';
                      }
                      if (address == ref.read(sessionProvider).user?['email']) {
                        return 'Gunakan email pendamping, bukan email akunmu sendiri.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email pendamping',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: relationship,
                    enabled: !busy,
                    maxLength: 80,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Isi hubungan atau panggilan pendamping.'
                        : null,
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
            ),
            if (error != null) ErrorNotice(error!),
            if (invitation != null)
              BlueCard(
                child: Column(
                  children: [
                    const Text(
                      'Berikan kode ini secara pribadi kepada pendamping. Berlaku 48 jam dan hanya dapat dipakai oleh email yang kamu undang.',
                    ),
                    const SizedBox(height: 8),
                    const SoftLabel(
                      'Kode Undangan Pribadi',
                      inverse: true,
                      icon: Icons.shield_outlined,
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      invitation!['invitation_token'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Berlaku hingga ${DateTime.parse(invitation!['expires_at']).toLocal().toString().substring(0, 16)}',
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: hopelyBlue,
                      ),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: invitation!['invitation_token']),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kode disalin. Kirimkan secara pribadi kepada kerabat.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Salin Kode Undangan'),
                    ),
                  ],
                ),
              ),
            SectionHeading(
              'Kerabat Terhubung (${rows.where((r) => r['invitation_status'] == 'accepted').length})',
            ),
            if (rows.isEmpty)
              const CareCard(
                child: Text(
                  'Belum ada undangan. Mulai dengan email orang yang kamu percaya.',
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
                    Text(row['invited_email']),
                    const SizedBox(height: 8),
                    SoftLabel(
                      const {
                            'accepted': 'Terhubung',
                            'pending': 'Menunggu diterima',
                            'revoked': 'Akses dicabut',
                          }[row['invitation_status']] ??
                          row['invitation_status'],
                    ),
                    for (final e in const {
                      'can_view_wellbeing_summary': 'Ringkasan wellbeing',
                      'can_view_symptom_summary': 'Ringkasan keluhan',
                      'can_view_treatment_schedule': 'Jadwal perawatan',
                      'can_view_activity_status': 'Status aktivitas',
                      'can_receive_support_alert': 'Pengingat dukungan',
                    }.entries)
                      if (row['invitation_status'] != 'revoked')
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.value),
                          value: row['permissions'][e.key] == true,
                          onChanged: busy
                              ? null
                              : (v) async {
                                  setState(() => busy = true);
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
                                  } finally {
                                    if (mounted) {
                                      setState(() => busy = false);
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
