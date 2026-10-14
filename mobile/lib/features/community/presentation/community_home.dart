import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/widgets/stitch.dart';
import '../data/community_repository.dart';
import 'community_widgets.dart';

class CommunityHomeScreen extends ConsumerWidget {
  const CommunityHomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => CommunityScaffold(
    title: 'Support Circle',
    root: true,
    actions: [
      IconButton(
        tooltip: 'Keamanan komunitas',
        icon: const Icon(Icons.shield_outlined),
        onPressed: () => context.push('/community/safety'),
      ),
    ],
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
            const Heading(
              'Kamu tidak sendiri.',
              'Ruang aman untuk saling menguatkan.',
            ),
            CareCard(
              color: circleLightBlue.withValues(alpha: .6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.diversity_1_outlined,
                    size: 36,
                    color: circleDeepBlue,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Temukan teman seperjalanan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bercerita saat kamu siap. Mendengarkan juga merupakan bentuk dukungan.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => open('/community/discover'),
                      icon: const Icon(Icons.search),
                      label: const Text('Cari komunitas'),
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.groups_outlined, size: 18),
                  label: const Text('Komunitasku'),
                  onPressed: () => open('/community/mine'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Ceritaku'),
                  onPressed: () => open('/community/feed?mine=1'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeading(
              'Komunitas yang kamu ikuti',
              action: 'Lihat semua',
              onTap: () => open('/community/mine'),
            ),
            if (joined.isEmpty)
              CommunityEmptyState(
                'Mulai dari ruang yang nyaman',
                'Belum ada komunitas yang kamu ikuti. Kamu bebas membaca dan memilih kapan ingin bergabung.',
                action: TextButton(
                  onPressed: () => open('/community/discover'),
                  child: const Text('Temukan komunitas'),
                ),
              ),
            for (final c in joined)
              CommunityCard(
                c,
                onOpen: () => open('/community/groups/${c['id']}'),
              ),
            SectionHeading(
              data['recommendation_method'] == 'metadata'
                  ? 'Sesuai minatmu'
                  : 'Pilihan komunitas',
              action: 'Atur minat',
              onTap: () => open('/community/preferences'),
            ),
            if (recommended.isEmpty)
              const CommunityEmptyState(
                'Ruang sedang disiapkan',
                'Komunitas akan muncul di sini setelah tersedia.',
              ),
            for (final r in recommended)
              CommunityCard(
                Map<String, dynamic>.from(r['community']),
                reason: r['reason'] as String?,
                onOpen: () => open('/community/groups/${r['community']['id']}'),
              ),
            SectionHeading(
              'Cerita dari komunitas',
              action: 'Lihat semua',
              onTap: () => open('/community/feed'),
            ),
            if (recent.isEmpty)
              const CommunityEmptyState(
                'Belum ada cerita terbit',
                'Cerita baru akan muncul setelah siap dibagikan.',
              ),
            for (final p in recent)
              CommunityPostCard(p, key: ValueKey(p['id']), onChanged: reload),
            const CommunitySafetyBanner(),
          ],
        );
      },
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
    title: 'Temukan Komunitas',
    body: Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  TextField(
                    controller: search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => refresh(),
                    decoration: InputDecoration(
                      labelText: 'Cari komunitas',
                      hintText: 'Nama komunitas',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Jalankan pencarian',
                        onPressed: refresh,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('Semua'),
                            selected: category == null,
                            onSelected: (_) {
                              category = null;
                              refresh();
                            },
                          ),
                        ),
                        for (final e in communityCategories.entries)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(e.value),
                              selected: category == e.key,
                              onSelected: (_) {
                                category = e.key;
                                refresh();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: sort,
                    decoration: const InputDecoration(labelText: 'Urutkan'),
                    items: const [
                      DropdownMenuItem(
                        value: 'relevant',
                        child: Text('Paling relevan'),
                      ),
                      DropdownMenuItem(value: 'newest', child: Text('Terbaru')),
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('Paling aktif (7 hari)'),
                      ),
                    ],
                    onChanged: (v) {
                      sort = v!;
                      refresh();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
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
                    CommunityCard(
                      c,
                      onOpen: () async {
                        await context.push('/community/groups/${c['id']}');
                        if (mounted) reload();
                      },
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
}
