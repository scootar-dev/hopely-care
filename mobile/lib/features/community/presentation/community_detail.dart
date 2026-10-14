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
      title: 'Ruang Komunitas',
      actions: [
        IconButton(
          tooltip: 'Keamanan komunitas',
          onPressed: () => context.push('/community/safety'),
          icon: const Icon(Icons.shield_outlined),
        ),
      ],
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
          return CommunityBody(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: circleLightBlue,
                  child: Icon(
                    Icons.diversity_1_outlined,
                    color: circleBlue,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Heading(community['name'], community['description']),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  SoftLabel(
                    communityCategories[community['category']] ?? 'Dukungan',
                  ),
                  SoftLabel(
                    '${community['member_count']} anggota',
                    icon: Icons.people_outline,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: busy ? null : () => membership(community, reload),
                icon: Icon(
                  joined
                      ? Icons.check_circle_outline
                      : Icons.group_add_outlined,
                ),
                label: Text(
                  joined ? 'Sudah bergabung • Keluar' : 'Gabung komunitas',
                ),
              ),
              const SizedBox(height: 16),
              if (error != null) ErrorNotice(error!),
              CareCard(
                padding: 14,
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Pedoman ruang ini'),
                  leading: const Icon(
                    Icons.verified_user_outlined,
                    color: circleBlue,
                  ),
                  children: [
                    for (final rule in data['detail']['guidelines'] as List)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text('• $rule'),
                      ),
                  ],
                ),
              ),
              const CommunitySafetyBanner(),
              if (joined)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context.push(
                        '/community/compose?community=${widget.id}',
                      );
                      if (mounted) reload();
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Bagikan cerita'),
                  ),
                ),
              const SectionHeading('Cerita di komunitas'),
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
            ],
          );
        },
      ),
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
  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: widget.mine ? 'Ceritaku' : 'Cerita Komunitas',
    actions: [
      IconButton(
        tooltip: 'Bagikan cerita',
        icon: const Icon(Icons.edit_note),
        onPressed: () async {
          await context.push('/community/compose');
          if (mounted) {
            setState(() {
              page = 1;
              version++;
            });
          }
        },
      ),
    ],
    body: DataPage(
      key: ValueKey('$page-$version'),
      load: () => ref
          .read(communityRepositoryProvider)
          .feed(mine: widget.mine, page: page),
      builder: (value, reload) {
        final data = value as Json;
        return CommunityBody(
          children: [
            const CommunitySafetyBanner(),
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
    title: 'Komunitasku',
    actions: [
      IconButton(
        tooltip: 'Pengaturan komunitas',
        icon: const Icon(Icons.tune),
        onPressed: () => context.push('/community/preferences'),
      ),
    ],
    body: DataPage(
      key: ValueKey(page),
      load: () => ref.read(communityRepositoryProvider).mine(page: page),
      builder: (value, reload) {
        final data = value as Json;
        return CommunityBody(
          children: [
            const Heading(
              'Ruang yang kamu pilih',
              'Kamu bebas bergabung dan berhenti kapan saja.',
            ),
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
              CommunityCard(
                c,
                onOpen: () async {
                  await context.push('/community/groups/${c['id']}');
                  if (context.mounted) reload();
                },
                footer: c['membership_status'] == 'active'
                    ? TextButton(
                        onPressed: () async {
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
                        child: const Text('Keluar dari komunitas'),
                      )
                    : null,
              ),
            CommunityPagination(data, (v) => setState(() => page = v)),
            const CareCard(
              child: ActionLink(
                'Pengaturan & notifikasi komunitas',
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
