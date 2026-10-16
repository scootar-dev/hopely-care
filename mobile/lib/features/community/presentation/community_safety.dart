import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/ui.dart';
import '../data/community_repository.dart';
import 'community_widgets.dart';

class CommunitySafetyScreen extends ConsumerStatefulWidget {
  const CommunitySafetyScreen({super.key});
  @override
  ConsumerState<CommunitySafetyScreen> createState() => _SafetyState();
}

class _SafetyState extends ConsumerState<CommunitySafetyScreen> {
  int page = 1;
  String? unblocking;
  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Pedoman Ruang Aman',
    body: DataPage(
      key: ValueKey(page),
      load: () => ref.read(communityRepositoryProvider).safety(page: page),
      builder: (value, reload) {
        final data = value as Json, blocked = items(data['blocked_users']);
        final reports = Map<String, dynamic>.from(data['reports']);
        return CommunityBody(
          children: [
            // Hero card: Ruang Teduh
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: circleSurface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .03),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD3E4FE),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          color: circleBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified_user_outlined,
                                  size: 14,
                                  color: circleBlue,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'RUANG TEDUH',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: circleBlue,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Komitmen bersama menciptakan ruang yang aman, hangat, dan tanpa penghakiman.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volunteer_activism_outlined,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Konten dapat ditahan untuk ditinjau moderator.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Section: Pedoman Ruang Bersama - 4 Pilar Etik
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pedoman Ruang Bersama',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B1C30),
                  ),
                ),
                Text(
                  '4 Pilar Etik',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: circleBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 4 pillars from API guidelines or hardcoded
            _PillarCard(
              icon: Icons.favorite,
              iconColor: const Color(0xFF001453),
              iconBg: const Color(0xFFDDE1FF),
              title: 'Empati Penuh',
              description:
                  'Dengarkan tanpa menghakimi pilihan terapi atau kondisi emosional sesama pejuang.',
            ),
            _PillarCard(
              icon: Icons.lock,
              iconColor: circleBlue,
              iconBg: const Color(0xFFDCE9FF),
              title: 'Privasi Medis',
              description:
                  'Jaga kerahasiaan identitas pribadi dan dokumen medis sensitif demi kenyamanan bersama.',
            ),
            _PillarCard(
              icon: Icons.medical_services,
              iconColor: const Color(0xFF00174B),
              iconBg: const Color(0xFFDBE1FF),
              title: 'Bukan Pengganti Resep',
              description:
                  'Bagikan pengalaman personal sebagai penguat rasa, bukan anjuran medis pengganti dokter.',
            ),
            _PillarCard(
              icon: Icons.do_not_disturb_on,
              iconColor: const Color(0xFF0E1D2B),
              iconBg: const Color(0xFFD5E4F8),
              title: 'Bebas Promosi',
              description:
                  'Tidak diperkenankan menjual obat herbal, suplemen tanpa izin, atau pengobatan alternatif komersial.',
            ),
            // Community pledge quote card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: circleSurface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image placeholder
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.spa_outlined,
                        size: 40,
                        color: circleBlue.withValues(alpha: .4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ikrar Komunitas Sahabat',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3755C3),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"Di sini kita saling menguatkan langkah, merawat napas, dan menjalani hari ini bersama."',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Section: Fitur Perlindungan Anda
            const Text(
              'Fitur Perlindungan Anda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B1C30),
              ),
            ),
            const SizedBox(height: 12),
            // Protection features list
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Laporan Konten
                  _ProtectionRow(
                    icon: Icons.flag_outlined,
                    title: 'Laporan Konten Tidak Pantas',
                    subtitle: 'Status laporan dapat dilihat pada riwayat di bawah',
                    onTap: null,
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey.shade100,
                  ),
                  // Pengguna Diblokir
                  _ProtectionRow(
                    icon: Icons.block_outlined,
                    title: 'Pengguna yang Diblokir',
                    subtitle: '${blocked.length} akun diblokir',
                    onTap: () {},
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey.shade100,
                  ),
                  // Privasi Profil
                  _ProtectionRow(
                    icon: Icons.visibility_off_outlined,
                    title: 'Privasi Profil di Komunitas',
                    subtitle: 'Gunakan nama samaran / pejuang',
                    onTap: () => context.push('/community/preferences'),
                  ),
                ],
              ),
            ),
            // Riwayat Laporan (from API)
            if (items(reports).isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Laporanmu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                  Text(
                    '${items(reports).length} laporan',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final report in items(reports))
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .03),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportReasons[report['reason']] ?? 'Laporan konten',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        switch (report['status']) {
                          'resolved' => 'Selesai ditindaklanjuti',
                          'dismissed' =>
                            'Ditinjau • tidak ada pelanggaran yang ditetapkan',
                          'reviewed' => 'Sedang ditinjau',
                          _ => 'Menunggu peninjauan',
                        },
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        shortDate(report['created_at']),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              CommunityPagination(reports, (v) => setState(() => page = v)),
            ],
            // Blocked users section
            if (blocked.isNotEmpty) ...[
              const Text(
                'Pengguna yang Diblokir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B1C30),
                ),
              ),
              const SizedBox(height: 12),
              for (final user in blocked)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .03),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: circleSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.person_off_outlined,
                          color: circleBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          user['display_name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: unblocking != null
                            ? null
                            : () async {
                                setState(() => unblocking = user['id']);
                                try {
                                  await ref
                                      .read(communityRepositoryProvider)
                                      .unblock(user['id']);
                                  if (mounted) reload();
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(friendlyError(e))),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => unblocking = null);
                                  }
                                }
                              },
                        child: Text(
                          unblocking == user['id'] ? 'Membuka…' : 'Buka blokir',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            // Crisis guidance without inventing a hotline or response SLA.
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD97706),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFED7AA),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.support_agent,
                                color: Color(0xFFB45309),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'JIKA KAMU DALAM KRISIS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: circleBlue,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Komunitas bukan layanan darurat',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0B1C30),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Jika kamu berada dalam bahaya atau ingin menyakiti diri, hubungi layanan darurat setempat atau orang yang kamu percaya sekarang. Nomor bantuan berbeda menurut lokasi.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Cari bantuan langsung dari layanan resmi di wilayahmu. Hopely Care tidak memantau keadaan darurat secara real time.',
                          style: TextStyle(fontSize: 12, color: tertiaryInk),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Moderasi button
            if (data['can_moderate'] == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: FilledButton.icon(
                  onPressed: () async {
                    await context.push('/community/moderation');
                    if (mounted) reload();
                  },
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Antrean moderasi'),
                ),
              ),
            // Settings link
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .03),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ActionLink(
                'Pengaturan komunitas',
                '/community/preferences',
                icon: Icons.tune,
              ),
            ),
            // Footer
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Hopely Care • Pedoman keselamatan komunitas',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, description;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .03),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B1C30),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProtectionRow extends StatelessWidget {
  const _ProtectionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5EEFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: circleBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B1C30),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
        ],
      ),
    ),
  );
}

// -- CommunityPreferencesScreen & CommunityModerationScreen remain below --

class CommunityPreferencesScreen extends ConsumerWidget {
  const CommunityPreferencesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => CommunityScaffold(
    title: 'Pengaturan Komunitas',
    body: DataPage(
      load: ref.read(communityRepositoryProvider).preferences,
      builder: (data, reload) => _PreferenceForm(
        initial: data as Json,
        repo: ref.read(communityRepositoryProvider),
      ),
    ),
  );
}

class _PreferenceForm extends StatefulWidget {
  const _PreferenceForm({required this.initial, required this.repo});
  final Json initial;
  final CommunityRepository repo;
  @override
  State<_PreferenceForm> createState() => _PreferenceFormState();
}

class _PreferenceFormState extends State<_PreferenceForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      cancer = TextEditingController(),
      phase = TextEditingController();
  late bool notifications, recommend, emotional;
  bool busy = false;
  Object? error;
  String? notice;
  @override
  void initState() {
    super.initState();
    name.text = widget.initial['display_name'] as String? ?? 'Anggota';
    notifications = widget.initial['notifications_enabled'] == true;
    recommend = widget.initial['recommendation_enabled'] == true;
    final interests = widget.initial['interests'] as Map? ?? {};
    cancer.text = interests['cancer_type'] as String? ?? '';
    phase.text = interests['treatment_phase'] as String? ?? '';
    emotional = (interests['support_preferences'] as List? ?? []).contains(
      'dukungan emosional',
    );
  }

  @override
  void dispose() {
    name.dispose();
    cancer.dispose();
    phase.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
      notice = null;
    });
    try {
      await widget.repo.savePreferences({
        'display_name': name.text.trim(),
        'notifications_enabled': notifications,
        'recommendation_enabled': recommend,
        'interests': recommend
            ? {
                'cancer_type': cancer.text.trim().toLowerCase(),
                'treatment_phase': phase.text.trim().toLowerCase(),
                'support_preferences': [if (emotional) 'dukungan emosional'],
              }
            : <String, dynamic>{},
      });
      if (mounted) setState(() => notice = 'Pengaturan komunitas tersimpan.');
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: CommunityBody(
      children: [
        // Header
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEFF4FF), Color(0xFFDBEAFE)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilihanmu, kendalimu',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B1C30),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pengaturan ini hanya untuk Support Circle.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        // Display name card
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: name,
            maxLength: 60,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: 'Nama di komunitas',
              helperText: 'Terlihat pada semua cerita dan komentarmu.',
            ),
            validator: (v) => (v?.trim().length ?? 0) < 2
                ? 'Isi nama minimal 2 karakter.'
                : null,
          ),
        ),
        // Notifications toggle card
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Notifikasi komunitas',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Pembaruan komentar, dukungan, laporan, dan moderasi. Tidak memuat isi cerita di notifikasi.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            value: notifications,
            onChanged: busy ? null : (v) => setState(() => notifications = v),
            activeThumbColor: circleBlue,
          ),
        ),
        // Interests card
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Cocokkan dengan minat saya',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Izinkan minat yang saya isi di bawah dikirim ke layanan pencocokan komunitas.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                value: recommend,
                onChanged: busy ? null : (v) => setState(() => recommend = v),
                activeThumbColor: circleBlue,
              ),
              if (recommend) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: cancer,
                  maxLength: 100,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Jenis kanker (opsional)',
                    hintText: 'Contoh: kanker payudara',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phase,
                  maxLength: 100,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Fase perjalanan (opsional)',
                    hintText: 'Kemoterapi, baru didiagnosis, atau pemulihan',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: emotional,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => emotional = v!),
                  title: const Text('Saya mencari dukungan emosional'),
                  activeColor: circleBlue,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Pilihan ini tidak terlihat oleh anggota lain. Menonaktifkannya menghapus minat tersimpan.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        if (error != null) ErrorNotice(error!),
        if (notice != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: circleSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              notice!,
              style: const TextStyle(
                color: circleDeepBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: busy ? null : save,
            style: FilledButton.styleFrom(
              backgroundColor: circleBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              busy ? 'Menyimpan…' : 'Simpan pengaturan',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );
}

class CommunityModerationScreen extends ConsumerStatefulWidget {
  const CommunityModerationScreen({super.key});
  @override
  ConsumerState<CommunityModerationScreen> createState() => _ModerationState();
}

class _ModerationState extends ConsumerState<CommunityModerationScreen> {
  String kind = 'post';
  int page = 1;
  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Antrean Moderasi',
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: CommunityTabBar(
            tabs: const ['Cerita', 'Komentar', 'Laporan'],
            selected: const ['post', 'comment', 'report'].indexOf(kind),
            onChanged: (i) => setState(() {
              kind = const ['post', 'comment', 'report'][i];
              page = 1;
            }),
          ),
        ),
        Expanded(
          child: DataPage(
            key: ValueKey('$kind-$page'),
            load: () => ref.read(communityRepositoryProvider).queue(kind, page),
            builder: (value, reload) {
              final data = value as Json;
              return CommunityBody(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: circleSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: circleBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tinjau konteks, privasi, dan keamanan isi sebelum memutuskan.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (items(data).isEmpty)
                    const CommunityEmptyState(
                      'Antrean sudah bersih',
                      'Tidak ada konten yang menunggu peninjauan pada kategori ini.',
                    ),
                  for (final item in items(data))
                    _ModerationItemCard(
                      item: item,
                      kind: kind,
                      onReview: (action) => review(item, action, reload),
                    ),
                  CommunityPagination(data, (v) => setState(() => page = v)),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
  Future<void> review(Json item, String action, VoidCallback reload) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ReviewDialog(
        repo: ref.read(communityRepositoryProvider),
        item: item,
        action: action,
      ),
    );
    if (mounted && changed == true) reload();
  }
}

class _ModerationItemCard extends StatelessWidget {
  const _ModerationItemCard({
    required this.item,
    required this.kind,
    required this.onReview,
  });
  final Json item;
  final String kind;
  final ValueChanged<String> onReview;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['community_name'] as String? ?? 'Komunitas',
          style: const TextStyle(
            color: circleBlue,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item['content'] as String? ?? '',
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
        if (item['has_image'] == true)
          CommunityImage(
            item['post_id'],
            review: true,
            revision: item['revision'],
          ),
        if (item['reason'] != null) ...[
          const SizedBox(height: 10),
          Text(
            'Alasan: ${reportReasons[item['reason']] ?? item['reason']}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
        if (item['description'] != null)
          Text(
            item['description'] as String,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (kind != 'report')
              Expanded(
                child: FilledButton(
                  onPressed: item['can_approve'] == false
                      ? null
                      : () => onReview('approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: circleBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Terbitkan'),
                ),
              ),
            if (kind != 'report') const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => onReview('remove'),
                child: const Text('Hapus'),
              ),
            ),
            if (kind == 'report') ...[
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () => onReview('dismiss'),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({
    required this.repo,
    required this.item,
    required this.action,
  });
  final CommunityRepository repo;
  final Json item;
  final String action;
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final note = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  Object? error;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repo.review(widget.item, widget.action, note.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(switch (widget.action) {
      'approve' => 'Terbitkan konten?',
      'remove' => 'Hapus publikasi?',
      _ => 'Tutup laporan?',
    }),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: note,
              maxLength: 500,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Alasan keputusan moderator',
              ),
              validator: (v) => (v?.trim().length ?? 0) < 3
                  ? 'Tuliskan alasan singkat.'
                  : null,
            ),
            if (error != null) ErrorNotice(error!),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: busy ? null : save,
        child: Text(busy ? 'Menyimpan…' : 'Simpan keputusan'),
      ),
    ],
  );
}
