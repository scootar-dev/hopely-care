import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/widgets/stitch.dart';
import '../data/community_repository.dart';
import 'community_dialogs.dart';

const circleBlue = Color(0xFF2563EB);
const circleDeepBlue = Color(0xFF1E40AF);
const circleLightBlue = Color(0xFFDBEAFE);
const circleCanvas = Color(0xFFF8FAFF);
const communityCategories = {
  'cancer': 'Jenis kanker',
  'treatment': 'Fase treatment',
  'emotional': 'Dukungan emosional',
  'survivor': 'Survivor',
  'caregiver': 'Caregiver',
};
const supportReactions = {
  'support': 'Dukungan',
  'encouragement': 'Semangat',
  'thanks': 'Terima kasih',
};
const reportReasons = {
  'misinformation': 'Informasi medis berbahaya',
  'harassment': 'Pelecehan atau kebencian',
  'spam': 'Spam atau promosi',
  'privacy': 'Privasi seseorang',
  'unsafe': 'Konten tidak aman',
  'other': 'Lainnya',
};
String moderationLabel(dynamic status) => switch (status) {
  'pending' => 'Menunggu peninjauan',
  'flagged' => 'Ditahan untuk ditinjau',
  'removed' => 'Publikasi dihapus moderator',
  _ => 'Pengalaman pribadi',
};
String shortDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  return date == null
      ? ''
      : DateFormat('dd/MM/yyyy • HH:mm').format(date.toLocal());
}

class CommunityScaffold extends StatelessWidget {
  const CommunityScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.root = false,
  });
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool root;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: circleCanvas,
        colorScheme: theme.colorScheme.copyWith(
          primary: circleBlue,
          secondary: circleDeepBlue,
          surface: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: circleBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: BackHomeButton(fallback: root ? '/home' : '/community'),
          title: Text(title),
          actions: actions,
        ),
        body: SafeArea(top: false, child: body),
      ),
    );
  }
}

class CommunityBody extends StatelessWidget {
  const CommunityBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: children,
      ),
    ),
  );
}

class CommunitySafetyBanner extends StatelessWidget {
  const CommunitySafetyBanner({super.key, this.sharing = false});
  final bool sharing;
  @override
  Widget build(BuildContext context) => CareCard(
    color: circleLightBlue.withValues(alpha: .45),
    padding: 16,
    radius: 18,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.verified_user_outlined,
          color: circleDeepBlue,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            sharing
                ? 'Hindari membagikan informasi pribadi atau medis yang tidak ingin diketahui orang lain. Cerita dan foto yang kamu pilih dapat dibaca pengguna Hopely Care setelah ditinjau.'
                : 'Informasi kesehatan di komunitas berasal dari pengalaman pengguna dan tidak menggantikan saran tenaga kesehatan.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: circleDeepBlue,
            ),
          ),
        ),
      ],
    ),
  );
}

class CommunityEmptyState extends StatelessWidget {
  const CommunityEmptyState(this.title, this.message, {super.key, this.action});
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => CareCard(
    child: Column(
      children: [
        const CircleAvatar(
          radius: 27,
          backgroundColor: circleLightBlue,
          child: Icon(Icons.forum_outlined, color: circleBlue),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    ),
  );
}

class CommunityCard extends StatelessWidget {
  const CommunityCard(
    this.community, {
    super.key,
    this.reason,
    this.onOpen,
    this.footer,
  });
  final Json community;
  final String? reason;
  final VoidCallback? onOpen;
  final Widget? footer;
  @override
  Widget build(BuildContext context) {
    final status = community['membership_status'];
    return CareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: circleLightBlue,
                child: Icon(
                  community['category'] == 'emotional'
                      ? Icons.favorite_outline
                      : Icons.diversity_1_outlined,
                  color: circleBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community['name'] as String,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      communityCategories[community['category']] ??
                          'Ruang dukungan',
                      style: const TextStyle(
                        fontSize: 12,
                        color: circleDeepBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(community['description'] as String),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              Text(
                '${community['member_count'] ?? 0} anggota',
                style: const TextStyle(fontSize: 12),
              ),
              if (status != null)
                SoftLabel(switch (status) {
                  'active' => 'Sudah bergabung',
                  'pending' => 'Menunggu persetujuan',
                  'banned' => 'Keanggotaan dibatasi',
                  _ => 'Pernah bergabung',
                }),
            ],
          ),
          if (reason != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                reason!,
                style: const TextStyle(fontSize: 12, color: circleDeepBlue),
              ),
            ),
          if (status != 'banned')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed:
                    onOpen ??
                    () => context.push('/community/groups/${community['id']}'),
                label: const Text('Lihat komunitas'),
                icon: const Icon(Icons.arrow_forward, size: 18),
              ),
            ),
          ?footer,
        ],
      ),
    );
  }
}

class CommunityPagination extends StatelessWidget {
  const CommunityPagination(this.data, this.onPage, {super.key});
  final Json data;
  final ValueChanged<int> onPage;
  @override
  Widget build(BuildContext context) {
    final current = data['page'] as int? ?? 1,
        last = data['last_page'] as int? ?? 1;
    if (last <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: 'Halaman sebelumnya',
          onPressed: current > 1 ? () => onPage(current - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$current / $last'),
        IconButton(
          tooltip: 'Halaman berikutnya',
          onPressed: current < last ? () => onPage(current + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class CommunityImage extends ConsumerStatefulWidget {
  const CommunityImage(
    this.postId, {
    super.key,
    this.review = false,
    this.revision,
  });
  final String postId;
  final bool review;
  final dynamic revision;
  @override
  ConsumerState<CommunityImage> createState() => _CommunityImageState();
}

class _CommunityImageState extends ConsumerState<CommunityImage> {
  late Future<dynamic> image = load();
  Future<dynamic> load() => ref
      .read(apiProvider)
      .get(
        '/community/posts/${widget.postId}/image${widget.review ? '?review=1' : ''}',
      );
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: FutureBuilder<dynamic>(
      future: image,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorNotice(
            snapshot.error!,
            retry: () => setState(() => image = load()),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.memory(
            base64Decode(snapshot.data['base64'] as String),
            fit: BoxFit.contain,
            width: double.infinity,
            semanticLabel: 'Foto yang dibagikan penulis',
            gaplessPlayback: false,
            errorBuilder: (_, e, stack) =>
                const Text('Foto belum dapat ditampilkan.'),
          ),
        );
      },
    ),
  );
}

class CommunityReactionBar extends StatelessWidget {
  const CommunityReactionBar({
    super.key,
    required this.selected,
    required this.count,
    required this.onReact,
  });
  final String? selected;
  final int count;
  final ValueChanged<String>? onReact;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$count dukungan',
        style: const TextStyle(fontSize: 12, color: circleDeepBlue),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final e in supportReactions.entries)
            FilterChip(
              label: Text(e.value, style: const TextStyle(fontSize: 12)),
              avatar: Icon(
                e.key == 'thanks'
                    ? Icons.volunteer_activism_outlined
                    : Icons.favorite_outline,
                size: 17,
              ),
              selected: selected == e.key,
              onSelected: onReact == null ? null : (_) => onReact!(e.key),
            ),
        ],
      ),
    ],
  );
}

class CommunityPostCard extends ConsumerStatefulWidget {
  const CommunityPostCard(
    this.post, {
    super.key,
    required this.onChanged,
    this.detail = false,
  });
  final Json post;
  final VoidCallback onChanged;
  final bool detail;
  @override
  ConsumerState<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends ConsumerState<CommunityPostCard> {
  late Json post = widget.post;
  bool busy = false;
  Object? error;
  @override
  void didUpdateWidget(covariant CommunityPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) post = widget.post;
  }

  Future<void> react(String type) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final repo = ref.read(communityRepositoryProvider);
      Json updated;
      if (post['my_reaction'] == type) {
        await repo.unreact(post['id']);
        updated = await repo.post(post['id']);
      } else {
        updated = await repo.react(post['id'], type);
      }
      if (mounted) setState(() => post = updated);
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> menu(String action) async {
    if (action == 'edit') {
      await context.push('/community/compose?post=${post['id']}');
      if (mounted) widget.onChanged();
      return;
    }
    final changed = await communityContentAction(
      context,
      ref.read(communityRepositoryProvider),
      action,
      'post',
      post,
    );
    if (mounted && changed) {
      if (widget.detail && action != 'report') {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/community');
        }
      } else {
        widget.onChanged();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = post['author'] as Map;
    final own = post['is_own'] == true;
    return CareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: circleLightBlue,
                child: Icon(Icons.person_outline, color: circleBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author['display_name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      shortDate(post['created_at']),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Pilihan cerita',
                onSelected: menu,
                itemBuilder: (_) => [
                  if (own && post['moderation_status'] != 'removed')
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit cerita'),
                    ),
                  if (own)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus cerita'),
                    ),
                  if (!own)
                    const PopupMenuItem(
                      value: 'report',
                      child: Text('Laporkan cerita'),
                    ),
                  if (!own)
                    const PopupMenuItem(
                      value: 'block',
                      child: Text('Blokir pengguna'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post['community_name'] as String? ?? '',
            style: const TextStyle(
              color: circleBlue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              SoftLabel(moderationLabel(post['moderation_status'])),
              if (post['is_demo'] == true) const SoftLabel('Contoh sintetis'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post['content'] as String,
            maxLines: widget.detail ? null : 5,
            overflow: widget.detail ? null : TextOverflow.ellipsis,
            style: const TextStyle(height: 1.65),
          ),
          if (post['has_image'] == true)
            if (widget.detail)
              CommunityImage(post['id'], revision: post['revision'])
            else
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(Icons.image_outlined, color: circleBlue, size: 18),
                    SizedBox(width: 6),
                    Text('Foto dalam cerita'),
                  ],
                ),
              ),
          const SizedBox(height: 16),
          CommunityReactionBar(
            selected: post['my_reaction'] as String?,
            count: post['reaction_count'] as int? ?? 0,
            onReact: !busy && post['can_participate'] == true ? react : null,
          ),
          if (error != null) ErrorNotice(error!),
          if (!widget.detail)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  await context.push('/community/posts/${post['id']}');
                  if (mounted) widget.onChanged();
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(
                  '${post['comment_count'] ?? 0} komentar • Baca cerita',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CommunityCommentItem extends StatelessWidget {
  const CommunityCommentItem(this.comment, {super.key, required this.onAction});
  final Json comment;
  final ValueChanged<String> onAction;
  @override
  Widget build(BuildContext context) => CareCard(
    padding: 16,
    radius: 18,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                comment['author']['display_name'],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Pilihan komentar',
              onSelected: onAction,
              itemBuilder: (_) => [
                if (comment['is_own'] == true)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus komentar'),
                  ),
                if (comment['is_own'] != true)
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Laporkan komentar'),
                  ),
                if (comment['is_own'] != true)
                  const PopupMenuItem(
                    value: 'block',
                    child: Text('Blokir pengguna'),
                  ),
              ],
            ),
          ],
        ),
        Text(comment['content'], style: const TextStyle(height: 1.6)),
        const SizedBox(height: 8),
        Text(
          shortDate(comment['created_at']),
          style: const TextStyle(fontSize: 11),
        ),
        if (comment['moderation_status'] != 'approved')
          Text(
            moderationLabel(comment['moderation_status']),
            style: const TextStyle(color: circleDeepBlue, fontSize: 12),
          ),
      ],
    ),
  );
}
