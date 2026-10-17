import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api.dart';
import '../../../core/widgets/ui.dart';
import '../data/community_repository.dart';
import 'community_widgets.dart';

class CommunityHomeScreen extends ConsumerStatefulWidget {
  const CommunityHomeScreen({super.key});
  @override
  ConsumerState<CommunityHomeScreen> createState() => _CommunityHomeState();
}

class _CommunityHomeState extends ConsumerState<CommunityHomeScreen> {
  int _tabIndex = 0; // 0 = Untukmu, 1 = Komunitasku
  int _filterIndex = 0;
  final _filterLabels = const ['Semua', 'Kemoterapi', 'Payudara', 'Survivor'];

  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Komunitas',
    root: true,
    body: DataPage(
      load: ref.read(communityRepositoryProvider).home,
      builder: (value, reload) {
        final data = value as Json,
            joined = items(data['joined']),
            recent = items(data['recent']);
        final recommended = items(data['recommended']);
        Future<void> open(String path) async {
          await context.push(path);
          if (context.mounted) reload();
        }

        return CommunityBody(
          children: [
            // Subtitle
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                'Temukan teman seperjalanan.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),
            // Tab bar: Untukmu / Komunitasku
            CommunityTabBar(
              tabs: const ['Untukmu', 'Komunitasku'],
              selected: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
            // Tab content
            if (_tabIndex == 0) ...[
              // Filter chips
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CommunityFilterChips(
                  filters: _filterLabels,
                  selected: _filterIndex,
                  onChanged: (i) => setState(() => _filterIndex = i),
                ),
              ),
              // Recommended communities
              if (recommended.isEmpty && joined.isEmpty)
                const CommunityEmptyState(
                  'Mulai dari ruang yang nyaman',
                  'Belum ada komunitas yang ditemukan. Coba kategori lain atau jelajahi lebih banyak.',
                ),
              // Show recommended communities
              for (final r in recommended)
                CommunityCard(
                  Map<String, dynamic>.from(r['community']),
                  reason: r['reason'] as String?,
                  onOpen: () =>
                      open('/community/groups/${r['community']['id']}'),
                ),
              // Show joined communities in "Untukmu" too
              for (final c in joined)
                CommunityCard(
                  c,
                  onOpen: () => open('/community/groups/${c['id']}'),
                ),
              // Also show recent posts
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final p in recent)
                  CommunityPostCard(
                    p,
                    key: ValueKey(p['id']),
                    onChanged: reload,
                  ),
              ],
            ] else ...[
              // Komunitasku tab
              _KomunitaskuView(
                joined: joined,
                stats: data['stats'] as Map?,
                onOpen: open,
                onReload: reload,
              ),
            ],
            // Safety banner
            const CommunitySafetyBanner(),
          ],
        );
      },
    ),
  );
}

class _KomunitaskuView extends ConsumerWidget {
  const _KomunitaskuView({
    required this.joined,
    this.stats,
    required this.onOpen,
    required this.onReload,
  });
  final List<Json> joined;
  final Map? stats;
  final Future<void> Function(String) onOpen;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (joined.isEmpty) {
      return CommunityEmptyState(
        'Belum Ada Lingkaran Aktif',
        'Pilih lingkaran yang sesuai dengan langkah perjalanan Anda saat ini di tab "Untukmu".',
        action: FilledButton(
          onPressed: () => onOpen('/community/discover'),
          child: const Text('Jelajahi Lingkaran'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats header card
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
                      const Icon(
                        Icons.shield_outlined,
                        color: circleBlue,
                        size: 18,
                      ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
                            stats?['shared_posts']?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: circleDeepBlue,
                            ),
                          ),
                          const Text(
                            'Cerita Dibagikan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF526079),
                            ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stats?['support_received']?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: circleDeepBlue,
                            ),
                          ),
                          const Text(
                            'Dukungan Diterima',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF526079),
                            ),
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
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
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
        // Section: Lingkaran Tergabung
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
                  '${joined.length} ruang aktif',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => onOpen('/community/discover'),
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
        // My communities cards
        for (final c in joined)
          _JoinedCommunityCard(
            community: c,
            onOpen: () => onOpen('/community/groups/${c['id']}'),
          ),
      ],
    );
  }
}

class _JoinedCommunityCard extends StatelessWidget {
  const _JoinedCommunityCard({required this.community, required this.onOpen});
  final Json community;
  final VoidCallback onOpen;
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
            // Thumbnail
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: Colors.grey.shade400,
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'notif', child: Text('Notifikasi')),
                PopupMenuItem(value: 'leave', child: Text('Keluar')),
              ],
              onSelected: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
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

class CommunityDiscoveryScreen extends ConsumerStatefulWidget {
  const CommunityDiscoveryScreen({super.key});
  @override
  ConsumerState<CommunityDiscoveryScreen> createState() => _DiscoveryState();
}

class _DiscoveryState extends ConsumerState<CommunityDiscoveryScreen> {
  final search = TextEditingController();
  String? category;
  String sort = 'relevant', submitted = '';
  int page = 1, version = 0;
  int _cancerFilter = 0;
  int _phaseFilter = -1;
  int _focusFilter = -1;

  final _cancerTypes = const ['Semua', 'Payudara', 'Kolorektal', 'Paru'];
  final _phases = const ['Baru Didiagnosis', 'Kemoterapi', 'Radioterapi'];
  final _focuses = const ['Emosional', 'Nutrisi Sehat', 'Caregiver'];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void refresh() => setState(() {
    page = 1;
    submitted = search.text.trim();
    version++;
  });

  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Grup Dukungan Kanker ...',
    body: Column(
      children: [
        // Header section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(color: circleCanvas),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: circleSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diversity_1, size: 16, color: circleBlue),
                    const SizedBox(width: 6),
                    const Text(
                      'RUANG BERBAGI TEDUH',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: circleBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Temukan sesama pejuang dan pendamping yang saling menguatkan di setiap langkah perjalanan.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 22, color: Colors.grey.shade400),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: search,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => refresh(),
                        decoration: InputDecoration(
                          hintText: 'Cari komunitas atau topik...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Jenis Kanker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jenis Kanker',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                  Text(
                    'Pilihan Utama',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _cancerTypes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () {
                      setState(() => _cancerFilter = i);
                      refresh();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _cancerFilter == i ? circleBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _cancerFilter == i
                              ? circleBlue
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_cancerFilter == i) ...[
                            const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            _cancerTypes[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _cancerFilter == i
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Fase Treatment
              const Text(
                'Fase Treatment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B1C30),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _phases.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(
                      () => _phaseFilter = _phaseFilter == i ? -1 : i,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _phaseFilter == i ? circleBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _phaseFilter == i
                              ? circleBlue
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        _phases[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _phaseFilter == i
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Fokus Dukungan
              const Text(
                'Fokus Dukungan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B1C30),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _focuses.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final icons = [
                      Icons.favorite_outline,
                      Icons.spa_outlined,
                      Icons.favorite_border,
                    ];
                    return GestureDetector(
                      onTap: () => setState(
                        () => _focusFilter = _focusFilter == i ? -1 : i,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _focusFilter == i ? circleBlue : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _focusFilter == i
                                ? circleBlue
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icons[i],
                              size: 14,
                              color: _focusFilter == i
                                  ? Colors.white
                                  : circleBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _focuses[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _focusFilter == i
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Results header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text(
                'Lingkaran Terbuka',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B1C30),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: circleBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '3 Komunitas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Privat & Aman',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        // Results list
        Expanded(
          child: DataPage(
            key: ValueKey('$page-$version'),
            load: () => ref
                .read(communityRepositoryProvider)
                .discover(
                  search: submitted,
                  category: category,
                  sort: sort,
                  page: page,
                ),
            builder: (value, reload) {
              final data = value as Json, rows = items(data);
              return CommunityBody(
                children: [
                  if (rows.isEmpty)
                    const CommunityEmptyState(
                      'Belum ada yang cocok',
                      'Coba kata kunci atau kategori lain.',
                    ),
                  for (final c in rows)
                    _DiscoveryCommunityCard(
                      community: c,
                      onOpen: () async {
                        await context.push('/community/groups/${c['id']}');
                        if (mounted) reload();
                      },
                    ),
                  CommunityPagination(data, (v) => setState(() => page = v)),
                  // Safety banner at bottom
                  _DiscoverySafetyBanner(),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _DiscoveryCommunityCard extends StatelessWidget {
  const _DiscoveryCommunityCard({
    required this.community,
    required this.onOpen,
  });
  final Json community;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final name = community['name'] as String;
    final memberCount = community['member_count'] ?? 0;
    final description = community['description'] as String;
    final category = community['category'] as String?;

    // Category badge
    String categoryLabel;
    Color categoryColor;
    IconData categoryIcon;
    switch (category) {
      case 'survivor':
        categoryLabel = 'Remisi';
        categoryColor = const Color(0xFF4CAF50);
        categoryIcon = Icons.verified_outlined;
        break;
      case 'emotional':
        categoryLabel = 'Emosional';
        categoryColor = circleBlue;
        categoryIcon = Icons.favorite_outline;
        break;
      case 'caregiver':
        categoryLabel = 'Caregiver';
        categoryColor = circleBlue;
        categoryIcon = Icons.diversity_1_outlined;
        break;
      default:
        categoryLabel = 'Nutrisi';
        categoryColor = const Color(0xFF4CAF50);
        categoryIcon = Icons.eco_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image and info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Community image
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: circleSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
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
                    // Category badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                categoryIcon,
                                size: 12,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                categoryLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: categoryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $memberCount Anggota',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Community name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B1C30),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Bottom: activity + join button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '12 diskusi aktif hari ini',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              Material(
                color: circleBlue,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onOpen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Gabung',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscoverySafetyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.shield_outlined, color: circleBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Komitmen Kenyamanan Bersama',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B1C30),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Setiap lingkaran diawasi oleh fasilitator psiko-onkologi berlisensi guna memastikan percakapan yang penuh empati dan terjaga kerahasiaannya.',
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
  );
}
