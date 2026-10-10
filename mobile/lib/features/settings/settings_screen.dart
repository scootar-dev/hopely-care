import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/notifications/push_service.dart';
import '../../core/widgets/stitch.dart';
import '../../core/theme/theme.dart';
import 'profile_photo.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});
  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool busy = false;
  Object? error;
  Future<void> change(String type, bool accepted) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(apiProvider).put('/consents', {
        'consent_type': type,
        'accepted': accepted,
      });
      await ref.read(sessionProvider).refresh();
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
    final s = ref.watch(sessionProvider);
    const descriptions = {
      'HEALTH_DATA_PROCESSING': (
        'Pencatatan wellbeing',
        'Izinkan penyimpanan dan pengolahan data yang kamu masukkan untuk menjalankan fitur kesehatan.',
      ),
      'AI_JOURNAL_ANALYSIS': (
        'Analisis catatan oleh AI',
        'Catatan yang kamu pilih dapat dikirim ke layanan AI. Setiap jurnal tetap memiliki izin tersendiri.',
      ),
      'AI_CHAT_CONTEXT': (
        'Percakapan AI dengan konteks',
        'Kirim pesan dan konteks terbatas seperti check-in dan jadwal untuk jawaban yang lebih relevan.',
      ),
      'CAREGIVER_WELLBEING_SHARE': (
        'Berbagi ringkasan dengan pendamping',
        'Hanya jenis data yang kamu pilih pada izin pendamping. Isi jurnal dan chat tetap pribadi.',
      ),
      'CAREGIVER_ALERT': (
        'Pengingat dukungan untuk pendamping',
        'Izinkan pemberitahuan umum ketika sistem mendeteksi kebutuhan bantuan. Bukan layanan pemantauan darurat.',
      ),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Privasi & Persetujuan')),
      body: PageBody(
        children: [
          const Heading(
            'Kamu yang memegang kendali',
            'Semua pilihan dimulai nonaktif. Izin opsional dapat dicabut kapan saja.',
          ),
          for (final e in descriptions.entries)
            CareCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.value.$1),
                subtitle: Text(e.value.$2),
                value: s.consents.contains(e.key),
                onChanged: busy ? null : (v) => change(e.key, v),
              ),
            ),
          const Text(
            'Pencabutan menghentikan pemrosesan berikutnya dan menghapus wawasan turunan yang tersimpan. Data yang sudah terkirim ke provider sebelumnya tidak dapat ditarik kembali melalui aplikasi.',
          ),
          const SizedBox(height: 16),
          if (error != null) ErrorNotice(error!),
          FilledButton(
            onPressed: busy || s.needsConsent
                ? null
                : () => context.go(s.caregiver ? '/caregiver' : '/home'),
            child: const Text('Lanjutkan'),
          ),
          TextButton(
            onPressed: () async {
              await s.clear();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
            child: const Text('Keluar tanpa melanjutkan'),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Object? error;
  bool busy = false;
  Future<void> logout() async {
    setState(() => busy = true);
    try {
      final api = ref.read(apiProvider), session = ref.read(sessionProvider);
      final device =
          session.deviceId ??
          await session.storage.read(key: 'hopely.device_id');
      if (device != null) {
        await api.delete('/devices/$device');
      }
      await api.post('/auth/logout');
      await session.storage.delete(key: 'hopely.device_id');
      await session.clear();
      if (mounted) {
        context.go('/welcome');
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

  Future<void> removeAccount() async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus akun dan catatan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tindakan ini menghapus catatan, jurnal, percakapan, dan akses pendamping. Masukkan kata sandi untuk melanjutkan.',
            ),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata sandi'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, controller.text),
            child: const Text('Hapus akun'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.isEmpty) {
      return;
    }
    try {
      await ref.read(apiProvider).delete('/me', {'password': password});
      await ref.read(sessionProvider).clear();
      if (mounted) {
        context.go('/welcome');
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    return PageBody(
      children: [
        Center(
          child: Column(
            children: [
              const ProfilePhotoControls(),
              const SizedBox(height: 16),
              Text(
                s.profile?['display_name'] ?? s.user?['name'] ?? 'Profil',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              SoftLabel(
                s.caregiver ? 'Akun Kerabat' : 'Ruang Pribadimu',
                icon: Icons.favorite_outline,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        const BlueCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Setiap langkahmu berarti.',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
              Text(
                'Ada ruang untuk beristirahat, mencatat, dan melangkah sesuai kemampuanmu.',
              ),
            ],
          ),
        ),
        if (!s.caregiver && !s.needsConsent) const ProfileStats(),
        const SectionHeading('Pengaturan Cepat'),
        const CareCard(
          child: ActionLink(
            'Privasi & persetujuan',
            '/privacy',
            icon: Icons.lock_outline,
          ),
        ),
        if (!s.caregiver) ...[
          const CareCard(
            child: ActionLink(
              'Profil dan zona waktu',
              '/edit-profile',
              icon: Icons.person_outline,
            ),
          ),
          const CareCard(
            child: ActionLink(
              'Undang & kelola kerabat',
              '/care-circle',
              icon: Icons.people_outline,
            ),
          ),
          const CareCard(
            child: ActionLink(
              'Jurnal pribadi',
              '/journal',
              icon: Icons.edit_note,
            ),
          ),
        ],
        if (!s.caregiver)
          const CareCard(
            child: ActionLink(
              'Tools Kesehatan',
              '/tools',
              icon: Icons.health_and_safety_outlined,
            ),
          ),
        const CareCard(
          child: ActionLink(
            'Notifikasi',
            '/notifications',
            icon: Icons.notifications_none,
          ),
        ),
        CareCard(
          child: TextButton.icon(
            onPressed: () async {
              try {
                await PushService.enable(ref.read(apiProvider));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengaturan pengingat diperbarui.'),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pengingat perangkat belum dapat diaktifkan pada build ini.',
                      ),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Aktifkan pengingat perangkat'),
          ),
        ),
        if (error != null) ErrorNotice(error!),
        OutlinedButton(
          onPressed: busy ? null : logout,
          child: const Text('Keluar dari akun'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: busy ? null : removeAccount,
          child: const Text(
            'Hapus akun dan data',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

class ProfileEditor extends ConsumerStatefulWidget {
  const ProfileEditor({super.key});
  @override
  ConsumerState<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends ConsumerState<ProfileEditor> {
  final name = TextEditingController(), zone = TextEditingController();
  bool busy = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    final p = ref.read(sessionProvider).profile;
    name.text = p?['display_name'] ?? '';
    zone.text = p?['timezone'] ?? 'Asia/Jakarta';
  }

  @override
  void dispose() {
    name.dispose();
    zone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await ref.read(apiProvider).put('/profile', {
        'display_name': name.text,
        'timezone': zone.text,
        'onboarding_completed': true,
      });
      await ref.read(sessionProvider).refresh();
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profil Pribadi')),
    body: PageBody(
      children: [
        TextField(
          controller: name,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'Nama panggilan'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: zone,
          decoration: const InputDecoration(
            labelText: 'Zona waktu',
            helperText: 'Contoh: Asia/Jakarta',
          ),
        ),
        const SizedBox(height: 24),
        if (error != null) ErrorNotice(error!),
        FilledButton(
          onPressed: busy ? null : save,
          child: const Text('Simpan profil'),
        ),
      ],
    ),
  );
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      leading: BackHomeButton(
        fallback: ref.read(sessionProvider).caregiver ? '/caregiver' : '/home',
      ),
      title: const Text('Notifikasi'),
    ),
    body: DataPage(
      load: () => ref.read(apiProvider).get('/notifications'),
      builder: (data, reload) {
        final rows = items(data);
        return PageBody(
          children: [
            if (rows.isEmpty)
              const CareCard(child: Text('Belum ada pengingat baru.')),
            for (final n in rows)
              CareCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(n['title']),
                  subtitle: Text(n['body']),
                  leading: Icon(
                    n['read_at'] == null
                        ? Icons.notifications_active_outlined
                        : Icons.done,
                  ),
                  onTap: () async {
                    if (n['notification_type'] == 'support_alert' &&
                        ref.read(sessionProvider).caregiver) {
                      await context.push('/caregiver/alerts/${n['id']}');
                      reload();
                      return;
                    }
                    try {
                      await ref
                          .read(apiProvider)
                          .put('/notifications/${n['id']}/read', {});
                      reload();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(friendlyError(e))),
                        );
                      }
                    }
                  },
                ),
              ),
          ],
        );
      },
    ),
  );
}

class ProfileStats extends ConsumerStatefulWidget {
  const ProfileStats({super.key});
  @override
  ConsumerState<ProfileStats> createState() => _ProfileStatsState();
}

class _ProfileStatsState extends ConsumerState<ProfileStats> {
  late final Future<List<dynamic>> stats = Future.wait([
    ref.read(apiProvider).get('/journals'),
    ref.read(apiProvider).get('/checkins'),
    ref.read(apiProvider).get('/caregivers'),
  ]);
  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future: stats,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const CareCard(
          child: Text(
            'Ringkasan profil belum dapat dimuat. Pengaturan tetap tersedia.',
          ),
        );
      }
      if (!snapshot.hasData) {
        return const LinearProgressIndicator();
      }
      final data = snapshot.data!;
      final entries = [
        (
          'Jurnal',
          (data[0]['total'] ?? items(data[0]).length).toString(),
          Icons.edit_note,
        ),
        (
          'Check-in',
          (data[1]['total'] ?? items(data[1]).length).toString(),
          Icons.sentiment_satisfied_outlined,
        ),
        (
          'Kerabat',
          items(data[2])
              .where((r) => r['invitation_status'] == 'accepted')
              .length
              .toString(),
          Icons.people_outline,
        ),
      ];
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in entries)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: CareCard(
                      padding: 12,
                      child: Column(
                        children: [
                          Icon(e.$3, color: hopelyBlue),
                          const SizedBox(height: 12),
                          Text(
                            e.$2,
                            style: const TextStyle(
                              color: hopelyBlue,
                              fontSize: 22,
                            ),
                          ),
                          Text(e.$1, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (items(
            data[2],
          ).any((r) => r['invitation_status'] == 'accepted')) ...[
            const SectionHeading('Kerabatku'),
            for (final row in items(
              data[2],
            ).where((r) => r['invitation_status'] == 'accepted'))
              CareCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: lavender,
                    child: Icon(Icons.person_outline, color: hopelyBlue),
                  ),
                  title: Text(row['relationship_label']),
                  subtitle: Text(row['invited_email']),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/care-circle'),
                ),
              ),
          ],
        ],
      );
    },
  );
}
