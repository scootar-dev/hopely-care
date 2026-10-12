import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/widgets/stitch.dart';
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
    title: 'Keamanan Komunitas',
    body: DataPage(
      key: ValueKey(page),
      load: () => ref.read(communityRepositoryProvider).safety(page: page),
      builder: (value, reload) {
        final data = value as Json, blocked = items(data['blocked_users']);
        final reports = Map<String, dynamic>.from(data['reports']);
        return CommunityBody(
          children: [
            const Heading(
              'Saling menjaga ruang ini',
              'Kamu berhak merasa dihormati dan memegang kendali atas apa yang dibagikan.',
            ),
            const CommunitySafetyBanner(),
            const SectionHeading('Pedoman komunitas'),
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, text) in (data['guidelines'] as List).indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text('${i + 1}. $text'),
                    ),
                ],
              ),
            ),
            const CareCard(
              color: circleLightBlue,
              child: Text(
                'Cerita dan komentar dapat ditahan untuk peninjauan. Saat moderasi AI tidak tersedia, moderator meninjaunya secara manual. Foto selalu diperiksa moderator. Laporan tidak otomatis menghapus konten.',
              ),
            ),
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
            const SectionHeading('Riwayat laporanmu'),
            if (items(reports).isEmpty)
              const CareCard(child: Text('Belum ada laporan yang kamu kirim.')),
            for (final report in items(reports))
              CareCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reportReasons[report['reason']] ?? 'Laporan konten',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(switch (report['status']) {
                      'resolved' => 'Selesai ditindaklanjuti',
                      'dismissed' =>
                        'Ditinjau • tidak ada pelanggaran yang ditetapkan',
                      'reviewed' => 'Sedang ditinjau',
                      _ => 'Menunggu peninjauan',
                    }),
                    Text(
                      shortDate(report['created_at']),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            CommunityPagination(reports, (v) => setState(() => page = v)),
            const SectionHeading('Pengguna yang diblokir'),
            if (blocked.isEmpty)
              const CareCard(
                child: Text('Tidak ada pengguna yang kamu blokir.'),
              ),
            for (final user in blocked)
              CareCard(
                padding: 14,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(user['display_name']),
                  leading: const Icon(Icons.person_off_outlined),
                  subtitle: TextButton(
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
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(friendlyError(e))),
                                );
                            } finally {
                              if (mounted) setState(() => unblocking = null);
                            }
                          },
                    child: Text(
                      unblocking == user['id'] ? 'Membuka…' : 'Buka blokir',
                    ),
                  ),
                ),
              ),
            const CareCard(
              child: ActionLink(
                'Pengaturan komunitas',
                '/community/preferences',
                icon: Icons.tune,
              ),
            ),
          ],
        );
      },
    ),
  );
}

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
        const Heading(
          'Pilihanmu, kendalimu',
          'Pengaturan ini hanya untuk Support Circle.',
        ),
        CareCard(
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
        CareCard(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notifikasi komunitas'),
            subtitle: const Text(
              'Pembaruan komentar, dukungan, laporan, dan moderasi. Tidak memuat isi cerita di notifikasi.',
            ),
            value: notifications,
            onChanged: busy ? null : (v) => setState(() => notifications = v),
          ),
        ),
        CareCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cocokkan dengan minat saya'),
                subtitle: const Text(
                  'Izinkan minat yang saya isi di bawah dikirim ke layanan pencocokan komunitas. Tidak mengambil data dari profil medis, jurnal, atau chat AI.',
                ),
                value: recommend,
                onChanged: busy ? null : (v) => setState(() => recommend = v),
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
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Pilihan ini tidak terlihat oleh anggota lain. Menonaktifkannya menghapus minat tersimpan. Kamu tidak akan otomatis dimasukkan ke komunitas.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        if (error != null) ErrorNotice(error!),
        if (notice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(notice!, style: const TextStyle(color: circleDeepBlue)),
          ),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? 'Menyimpan…' : 'Simpan pengaturan'),
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
          child: Wrap(
            spacing: 8,
            children: [
              for (final e in const {
                'post': 'Cerita',
                'comment': 'Komentar',
                'report': 'Laporan',
              }.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: kind == e.key,
                  onSelected: (_) => setState(() {
                    kind = e.key;
                    page = 1;
                  }),
                ),
            ],
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
                  const CareCard(
                    color: circleLightBlue,
                    child: Text(
                      'Tinjau konteks, privasi, dan keamanan isi sebelum memutuskan. Cerita sendiri perlu ditinjau moderator lain.',
                    ),
                  ),
                  if (items(data).isEmpty)
                    const CommunityEmptyState(
                      'Antrean sudah bersih',
                      'Tidak ada konten yang menunggu peninjauan pada kategori ini.',
                    ),
                  for (final item in items(data))
                    CareCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['community_name'],
                            style: const TextStyle(
                              color: circleBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['content'],
                            style: const TextStyle(height: 1.6),
                          ),
                          if (item['has_image'] == true)
                            CommunityImage(
                              item['post_id'],
                              review: true,
                              revision: item['revision'],
                            ),
                          if (item['reason'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Alasan laporan: ${reportReasons[item['reason']] ?? item['reason']}',
                              ),
                            ),
                          if (item['description'] != null)
                            Text(item['description']),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (kind != 'report')
                                FilledButton(
                                  onPressed: () =>
                                      review(item, 'approve', reload),
                                  child: const Text('Terbitkan'),
                                ),
                              OutlinedButton(
                                onPressed: () => review(item, 'remove', reload),
                                child: const Text('Hapus publikasi'),
                              ),
                              if (kind == 'report')
                                TextButton(
                                  onPressed: () =>
                                      review(item, 'dismiss', reload),
                                  child: const Text('Tutup laporan'),
                                ),
                            ],
                          ),
                        ],
                      ),
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
      if (mounted)
        setState(() {
          error = e;
          busy = false;
        });
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
