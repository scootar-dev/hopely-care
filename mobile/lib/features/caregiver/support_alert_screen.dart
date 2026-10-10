import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';
import '../../core/theme/theme.dart';

class SupportAlertScreen extends ConsumerWidget {
  const SupportAlertScreen({super.key, required this.notificationId});
  final String notificationId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/caregiver'),
      title: const Text('Pengingat Dukungan'),
    ),
    body: DataPage(
      load: () => ref.read(apiProvider).get('/notifications'),
      builder: (data, reload) {
        final alert = items(data)
            .where(
              (n) =>
                  n['id'] == notificationId &&
                  n['notification_type'] == 'support_alert',
            )
            .firstOrNull;
        if (alert == null) {
          return const PageBody(
            children: [
              CareCard(
                child: Text(
                  'Pengingat ini tidak tersedia. Buka daftar notifikasi untuk melihat pengingat terbaru.',
                ),
              ),
              ActionLink('Lihat notifikasi', '/notifications'),
            ],
          );
        }
        return PageBody(
          children: [
            CareCard(
              color: const Color(0xFFB52332),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SoftLabel(
                    'PERHATIAN & DUKUNGAN',
                    icon: Icons.warning_amber_outlined,
                    inverse: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Luangkan waktu untuk hadir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ada pengingat dukungan untukmu. Tanyakan dengan tenang bagaimana orang yang kamu dampingi ingin dibantu.',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Diterima ${DateTime.parse(alert['created_at']).toLocal().toString().substring(0, 16)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: hopelyBlue,
                      ),
                      onPressed: () => context.go('/caregiver'),
                      child: const Text('Buka Ruang Kerabat'),
                    ),
                  ),
                ],
              ),
            ),
            const CareCard(
              color: skySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mendampingi dengan tenang',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Dengarkan tanpa menghakimi. Tanyakan izin sebelum menawarkan bantuan atau menghubungi orang lain.',
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Kamu bisa bertanya: “Aku ada di sini. Apa yang paling kamu butuhkan sekarang?”',
                  ),
                ],
              ),
            ),
            const PrivacyNote(
              'Pengingat ini bukan diagnosis atau layanan pemantauan darurat. Jika ada bahaya langsung atau keluhan medis mendesak, hubungi layanan darurat setempat atau tim perawatan melalui kontak yang kamu miliki.',
            ),
            if (alert['read_at'] == null)
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await ref
                        .read(apiProvider)
                        .put('/notifications/$notificationId/read', {});
                    reload();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
                    }
                  }
                },
                icon: const Icon(Icons.done),
                label: const Text('Tandai Sudah Dibaca'),
              ),
          ],
        );
      },
    ),
  );
}
