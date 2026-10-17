import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/widgets/stitch.dart';
import '../data/community_repository.dart';
import 'community_widgets.dart';
import 'community_dialogs.dart';

class CommunityDetailScreen extends ConsumerStatefulWidget {
  const CommunityDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<CommunityDetailScreen> createState() => _DetailState();
}

class _DetailState extends ConsumerState<CommunityDetailScreen> {
  int page = 1;
  bool busy = false;
  Object? error;
  int _storyFilter = 0;
  final _storyFilters = const ['Semua', 'Tanya Jawab', 'Harapan'];

  Future<void> membership(Json community, VoidCallback reload) async {
    final repo = ref.read(communityRepositoryProvider);
    if (community['membership_status'] != 'active') {
      if (await showCommunityJoin(context, repo, community) && mounted) {
        reload();
      }
      return;
    }
    if (!await communityConfirm(
      context,
      'Keluar dari komunitas?',
      'Ceritamu tetap tersedia sampai kamu menghapusnya. Kamu dapat mengelolanya di Ceritaku.',
      'Keluar',
    )) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await repo.leave(widget.id);
      if (mounted) reload();
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(communityRepositoryProvider);
    return CommunityScaffold(
      title: 'Grup Dukungan Kanker ...',
      body: DataPage(
        key: ValueKey(page),
        load: () async {
          final responses = await Future.wait([
            repo.detail(widget.id),
            repo.feed(communityId: widget.id, page: page),
          ]);
          return {'detail': responses[0], 'feed': responses[1]};
        },
        builder: (data, reload) {
          final community = Map<String, dynamic>.from(
            data['detail']['community'],
          );
          final feed = Map<String, dynamic>.from(data['feed']);
          final joined = community['membership_status'] == 'active';
          final memberCount = community['member_count'] ?? 0;
          return CommunityBody(
            children: [
              // Community info header card
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEFF4FF), Color(0xFFDBEAFE)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Community icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.diversity_1_outlined,
                            color: circleBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                community['name'] as String,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0B1C30),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.verified_outlined, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$memberCount Pejuang Tergabung',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Pedoman Aman button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: circleBlue.withValues(alpha: .2)),
                          ),
                          child: InkWell(
                            onTap: () => context.push('/community/safety'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chevron_left, size: 14, color: circleBlue),
                                const Text(
                                  'Pedoman\nAman',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: circleBlue,
                                    height: 1.3,
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 14, color: circleBlue),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      community['description'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Membership action
                    Row(
                      children: [
                        if (joined)
                          Row(
                            children: [
                              Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
                              const SizedBox(width: 6),
                              Text(
                                'Sudah Bergabung',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          )
                        else
                          FilledButton.icon(
                            onPressed: busy ? null : () => membership(community, reload),
                            icon: const Icon(Icons.group_add_outlined, size: 18),
                            label: const Text('Gabung komunitas'),
                          ),
                        const Spacer(),
                        if (joined)
                          InkWell(
                            onTap: busy ? null : () => membership(community, reload),
                            child: Text(
                              'Keluar Komunitas',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (error != null) ErrorNotice(error!),
              // Motivational quote card
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: circleSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.spa_outlined, size: 20, color: circleBlue.withValues(alpha: .6)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Langkah Anda hari ini sangat berharga.\nBeristirahatlah jika merasa lelah.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Story section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cerita Terbaru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                  Text(
                    'Diperbarui berkala',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Story filter tabs
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    for (int i = 0; i < _storyFilters.length; i++)
                      Padding(
                        padding: EdgeInsets.only(right: i < _storyFilters.length - 1 ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _storyFilter = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _storyFilter == i ? circleBlue : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _storyFilter == i ? circleBlue : Colors.grey.shade200,
                              ),
                            ),
                            child: Text(
                              i == 0
                                  ? '${_storyFilters[i]} (${items(feed).length})'
                                  : _storyFilters[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _storyFilter == i ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Posts
              if (items(feed).isEmpty)
                const CommunityEmptyState(
                  'Ruang untuk ceritamu',
                  'Belum ada cerita di sini. Setelah bergabung, kamu boleh mulai berbagi saat siap.',
                ),
              for (final post in items(feed))
                CommunityPostCard(
                  post,
                  key: ValueKey(post['id']),
                  onChanged: reload,
                ),
              CommunityPagination(feed, (v) => setState(() => page = v)),
              // Safety reassurance
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: circleSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: HopelyMark(size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ruang Tanpa Penghakiman',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0B1C30),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Setiap perasaan yang Anda alami adalah valid. Tidak perlu tergesa-gesa untuk selalu merasa kuat.',
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
              ),
            ],
          );
        },
      ),
      // FAB: Bagikan Cerita
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        child: FloatingActionButton.extended(
          onPressed: () async {
            await context.push('/community/compose?community=${widget.id}');
            if (mounted) setState(() {});
          },
          backgroundColor: circleBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.edit_note, size: 20),
          label: const Text(
            '+ Bagikan Cerita',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key, this.mine = false});
  final bool mine;
  @override
  ConsumerState<CommunityFeedScreen> createState() => _FeedState();
}

class _FeedState extends ConsumerState<CommunityFeedScreen> {
  int page = 1, version = 0;
  int _feedFilter = 0;
  final _feedFilters = const ['Semua Cerita', 'Pertanyaan', 'Kabar Baik'];
  
  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Komunitas',
    root: !widget.mine,
    body: DataPage(
      key: ValueKey('$page-$version'),
      load: () => ref
          .read(communityRepositoryProvider)
          .feed(mine: widget.mine, page: page),
      builder: (value, reload) {
        final data = value as Json;
        return CommunityBody(
          children: [
            // Header badge
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: circleSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_outlined, size: 14, color: circleBlue),
                  const SizedBox(width: 4),
                  const Text(
                    'RUANG SILATURAHMI AMAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: circleBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Heading
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kabar Lingkaran',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B1C30),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: circleSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_note, size: 20, color: circleBlue),
                    onPressed: () async {
                      await context.push('/community/compose');
                      if (mounted) {
                        setState(() {
                          page = 1;
                          version++;
                        });
                      }
                    },
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Saling berpegang tangan, berbagi langkah kecil dan pelukan penuh makna.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            // Filter tabs
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  for (int i = 0; i < _feedFilters.length; i++)
                    Padding(
                      padding: EdgeInsets.only(right: i < _feedFilters.length - 1 ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _feedFilter = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _feedFilter == i ? circleBlue : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _feedFilter == i ? circleBlue : Colors.grey.shade200,
                            ),
                          ),
                          child: Text(
                            _feedFilters[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _feedFilter == i ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Compose prompt
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_emotions_outlined, size: 22, color: Colors.grey.shade400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ada kelegaan kecil atau pert...',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: circleSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () async {
                        await context.push('/community/compose');
                        if (mounted) {
                          setState(() {
                            page = 1;
                            version++;
                          });
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined, size: 14, color: circleBlue),
                          const SizedBox(width: 4),
                          const Text(
                            'Tulis',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: circleBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Posts
            if (items(data).isEmpty)
              CommunityEmptyState(
                widget.mine
                    ? 'Cerita dimulai saat kamu siap'
                    : 'Belum ada cerita terbit',
                widget.mine
                    ? 'Bergabung dengan komunitas untuk membagikan ceritamu.'
                    : 'Kamu dapat menjelajahi komunitas sambil menunggu cerita baru.',
                action: TextButton(
                  onPressed: () => context.push('/community/discover'),
                  child: const Text('Jelajahi komunitas'),
                ),
              ),
            for (final post in items(data))
              CommunityPostCard(
                post,
                key: ValueKey(post['id']),
                onChanged: reload,
              ),
            CommunityPagination(data, (v) => setState(() => page = v)),
            // Bottom safety banner
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: circleSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.verified_user_outlined, color: circleBlue, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Komunitas diawasi penuh empati oleh tim psikolog Hopely Care. Ruang aman tanpa penghakiman atau perbandingan.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
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

class MyCommunitiesScreen extends ConsumerStatefulWidget {
  const MyCommunitiesScreen({super.key});
  @override
  ConsumerState<MyCommunitiesScreen> createState() => _MyCommunitiesState();
}

class _MyCommunitiesState extends ConsumerState<MyCommunitiesScreen> {
  int page = 1;
  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Komunitas',
    root: true,
    body: DataPage(
      key: ValueKey(page),
      load: () => ref.read(communityRepositoryProvider).mine(page: page),
      builder: (value, reload) {
        final data = value as Json;
        return CommunityBody(
          children: [
            // Badge
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: circleSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_outlined, size: 14, color: circleBlue),
                  const SizedBox(width: 4),
                  const Text(
                    'Ruang Aman Terverifikasi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: circleBlue,
                    ),
                  ),
                ],
              ),
            ),
            // Title
            const Text(
              'Komunitasku',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B1C30),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lingkaran tempatmu berbagi rasa dan saling menguatkan.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            // Tab bar (showing Komunitasku as active)
            CommunityTabBar(
              tabs: const ['Untukmu', 'Komunitasku'],
              selected: 1,
              onChanged: (i) {
                if (i == 0) context.go('/community');
              },
            ),
            // Stats card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: circleBlue, size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'Jejak Berbagimu',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: circleBlue,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: circleBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Privasi Aktif',
                              style: TextStyle(fontSize: 12, color: circleDeepBlue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${items(data).length}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: circleDeepBlue,
                                ),
                              ),
                              const Text(
                                'Cerita Dibagikan',
                                style: TextStyle(fontSize: 12, color: Color(0xFF526079)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '38',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: circleDeepBlue,
                                ),
                              ),
                              Text(
                                'Dukungan Diterima',
                                style: TextStyle(fontSize: 12, color: Color(0xFF526079)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        'Semua interaksi tersimpan aman & terlindungi.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lingkaran Tergabung',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                    Text(
                      '${items(data).length} ruang aktif',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () async {
                    await context.push('/community/discover');
                    if (context.mounted) reload();
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Cari Baru'),
                  style: TextButton.styleFrom(
                    foregroundColor: circleBlue,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Communities
            if (items(data).isEmpty)
              CommunityEmptyState(
                'Belum mengikuti komunitas',
                'Temukan ruang yang terasa sesuai denganmu.',
                action: FilledButton(
                  onPressed: () async {
                    await context.push('/community/discover');
                    if (context.mounted) reload();
                  },
                  child: const Text('Cari komunitas'),
                ),
              ),
            for (final c in items(data))
              _MyJoinedCard(
                community: c,
                onOpen: () async {
                  await context.push('/community/groups/${c['id']}');
                  if (context.mounted) reload();
                },
                onLeave: () async {
                  if (!await communityConfirm(
                    context,
                    'Keluar dari komunitas?',
                    'Cerita yang pernah dibagikan tetap dapat kamu hapus dari Ceritaku.',
                    'Keluar',
                  )) {
                    return;
                  }
                  try {
                    await ref
                        .read(communityRepositoryProvider)
                        .leave(c['id']);
                    if (context.mounted) reload();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(friendlyError(e))),
                      );
                    }
                  }
                },
              ),
            CommunityPagination(data, (v) => setState(() => page = v)),
            // Moderasi banner
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: circleSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.shield_outlined, color: circleBlue, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Moderasi Tim Psiko-Onkologi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B1C30),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Seluruh diskusi dipantau demi kehangatan dan rasa aman Anda.',
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
            ),
          ],
        );
      },
    ),
  );
}

class _MyJoinedCard extends StatelessWidget {
  const _MyJoinedCard({
    required this.community,
    required this.onOpen,
    required this.onLeave,
  });
  final Json community;
  final VoidCallback onOpen;
  final VoidCallback onLeave;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: circleSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.diversity_1_outlined,
                      color: circleBlue,
                      size: 24,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: circleBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community['name'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${community['member_count'] ?? 0} Pejuang • 12 kiriman baru hari ini',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Anggota Aktif',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade400),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'notif', child: Text('Notifikasi')),
                PopupMenuItem(value: 'leave', child: Text('Keluar')),
              ],
              onSelected: (v) {
                if (v == 'leave') onLeave();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active_outlined, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Notifikasi aktif',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Text(
                    'Buka Ruang',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: circleBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16, color: circleBlue),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
