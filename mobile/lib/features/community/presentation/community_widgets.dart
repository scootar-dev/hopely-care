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
import '../../settings/profile_photo.dart';
import '../../../core/widgets/account_action.dart';

const circleBlue = Color(0xFF2563EB);
const circleDeepBlue = Color(0xFF1E40AF);
const circleLightBlue = Color(0xFFDBEAFE);
const circleCanvas = Color(0xFFF8F9FF);
const circleSurface = Color(0xFFEFF4FF);
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
  if (date == null) return '';
  final now = DateTime.now();
  final diff = now.difference(date.toLocal());
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays == 1) return 'Kemarin';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return DateFormat('dd/MM/yyyy').format(date.toLocal());
}

class CommunityScaffold extends StatelessWidget {
  const CommunityScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.root = false,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool root;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
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
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: circleCanvas.withValues(alpha: .92),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          leading: root
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: circleSurface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.diversity_1,
                        color: circleBlue,
                        size: 20,
                      ),
                    ),
                  ),
                )
              : BackHomeButton(fallback: root ? '/home' : '/community'),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          actions: [
            ...?actions,
            IconButton(
              tooltip: 'Notifikasi',
              icon: const Icon(Icons.notifications_none_outlined, size: 22),
              onPressed: () => context.push('/notifications'),
            ),
            if (root) ...[
              IconButton(
                tooltip: 'Cari komunitas',
                icon: const Icon(Icons.search, size: 22),
                onPressed: () => context.push('/community/discover'),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: AccountAction(),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: AccountAction(),
              ),
          ],
        ),
        body: SafeArea(top: false, child: body),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: circleBlue,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            sharing
                ? 'Ruang ini dijaga bersama\nMohon hindari membagikan data rekam medis sensitif (NIK/Nomor Rekam Medis) atau promosi obat tanpa anjuran dokter.'
                : 'Ruang aman tanpa penghakiman • Dimoderasi tenaga pendamping.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(24),
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
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: circleSurface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(
            Icons.volunteer_activism,
            color: circleBlue,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0B1C30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
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
    this.showJoinButton = true,
  });
  final Json community;
  final String? reason;
  final VoidCallback? onOpen;
  final Widget? footer;
  final bool showJoinButton;
  @override
  Widget build(BuildContext context) {
    final status = community['membership_status'];
    final isJoined = status == 'active';
    final memberCount = community['member_count'] ?? 0;
    return Container(
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
      child: InkWell(
        onTap:
            onOpen ??
            () => context.push('/community/groups/${community['id']}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: thumbnail + name + member count
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: circleSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(
                      community['category'] == 'emotional'
                          ? Icons.favorite_outline
                          : Icons.diversity_1_outlined,
                      color: circleBlue,
                      size: 24,
                    ),
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
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B1C30),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.group_outlined,
                            size: 15,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$memberCount Teman Seperjalanan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              community['description'] as String,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            // Bottom: avatar stack + Gabung button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar stack
                _AvatarStack(community: community),
                // Join/View button
                if (showJoinButton && status != 'banned')
                  _CommunityActionButton(
                    isJoined: isJoined,
                    onOpen:
                        onOpen ??
                        () => context.push(
                          '/community/groups/${community['id']}',
                        ),
                  ),
              ],
            ),
            if (reason != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  reason!,
                  style: const TextStyle(fontSize: 12, color: circleDeepBlue),
                ),
              ),
            ?footer,
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.community});
  final Json community;
  @override
  Widget build(BuildContext context) {
    final count = (community['member_count'] as int?) ?? 0;
    final initials = _generateInitials(community['name'] as String? ?? '');
    final colors = [
      const Color(0xFFDCE9FF), // light blue
      const Color(0xFFDDE1FF), // secondary fixed
      const Color(0xFFE5EEFF), // surface container
    ];
    final textColors = [
      circleBlue,
      const Color(0xFF3755C3),
      Colors.grey.shade600,
    ];
    return SizedBox(
      height: 26,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < initials.length && i < 2; i++)
            Transform.translate(
              offset: Offset(i * -8.0, 0),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colors[i % colors.length],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    initials[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: textColors[i % textColors.length],
                    ),
                  ),
                ),
              ),
            ),
          if (count > 2)
            Transform.translate(
              offset: Offset((initials.length.clamp(0, 2)) * -8.0, 0),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EEFF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+${(count - 2).clamp(0, 99)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _generateInitials(String name) {
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return ['?'];
    if (words.length == 1) return [words[0][0].toUpperCase()];
    return [
      words[0][0].toUpperCase() +
          (words[0].length > 1 ? words[0][1].toUpperCase() : ''),
      words[1][0].toUpperCase() +
          (words[1].length > 1 ? words[1][1].toUpperCase() : ''),
    ];
  }
}

class _CommunityActionButton extends StatelessWidget {
  const _CommunityActionButton({required this.isJoined, required this.onOpen});
  final bool isJoined;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Material(
    color: isJoined ? circleBlue : circleSurface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          isJoined ? 'Tergabung' : 'Gabung',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isJoined ? Colors.white : circleBlue,
          ),
        ),
      ),
    ),
  );
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
  @override
  void didUpdateWidget(covariant CommunityImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId ||
        oldWidget.revision != widget.revision ||
        oldWidget.review != widget.review) {
      image = load();
    }
  }

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
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            base64Decode(snapshot.data['base64'] as String),
            fit: BoxFit.cover,
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
    this.commentCount = 0,
    this.onComment,
  });
  final String? selected;
  final int count;
  final int commentCount;
  final ValueChanged<String>? onReact;
  final VoidCallback? onComment;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      // Dukung button
      _ReactionButton(
        icon: Icons.volunteer_activism_outlined,
        label: 'Dukung',
        count: count,
        isSelected: selected != null,
        onTap: onReact != null ? () => onReact!('support') : null,
      ),
      const SizedBox(width: 12),
      // Komentar button
      _ReactionButton(
        icon: Icons.chat_bubble_outline,
        label: 'Komentar',
        count: commentCount,
        isSelected: false,
        onTap: onComment,
      ),
      const Spacer(),
      // Safety indicator
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Text(
            'Aman',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ],
  );
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? circleBlue : Colors.grey.shade500,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? circleBlue : Colors.grey.shade600,
                ),
              ),
              if (count > 0)
                Text(
                  '($count)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? circleBlue : Colors.grey.shade400,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
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
    if (busy) return;
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
    final authorName = author['display_name'] as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Author header
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: circleLightBlue,
                child: Text(
                  authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: circleBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Author badge
                        _AuthorBadge(post: post),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shortDate(post['created_at']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Pilihan cerita',
                icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
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
          const SizedBox(height: 14),
          // Content
          Text(
            post['content'] as String,
            maxLines: widget.detail ? null : 5,
            overflow: widget.detail ? null : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.65,
              color: Color(0xFF0B1C30),
            ),
          ),
          // Image
          if (post['has_image'] == true)
            CommunityImage(post['id'], revision: post['revision']),
          // Topic tag
          if (post['community_name'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: circleSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_outline,
                    size: 14,
                    color: circleBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post['community_name'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: circleBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Divider
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 12),
          // Reaction bar
          CommunityReactionBar(
            selected: post['my_reaction'] as String?,
            count: post['reaction_count'] as int? ?? 0,
            commentCount: post['comment_count'] as int? ?? 0,
            onReact: !busy && post['can_participate'] == true ? react : null,
            onComment: () async {
              await context.push('/community/posts/${post['id']}');
              if (mounted) widget.onChanged();
            },
          ),
          if (post['can_participate'] != true)
            TextButton(
              onPressed: () async {
                await context.push('/community/groups/${post['community_id']}');
                if (mounted) widget.onChanged();
              },
              child: Text(
                post['moderation_status'] == 'approved'
                    ? 'Gabung komunitas untuk memberi dukungan'
                    : 'Interaksi tersedia setelah cerita diterbitkan',
              ),
            ),
          if (error != null) ErrorNotice(error!),
          if (!widget.detail)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                onTap: () async {
                  await context.push('/community/posts/${post['id']}');
                  if (mounted) widget.onChanged();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Baca cerita selengkapnya →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: circleBlue,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuthorBadge extends StatelessWidget {
  const _AuthorBadge({required this.post});
  final Json post;
  @override
  Widget build(BuildContext context) {
    final status = post['moderation_status'];
    String label;
    if (status == 'pending') {
      label = 'Menunggu';
    } else if (post['is_demo'] == true) {
      label = 'Contoh';
    } else {
      label = 'Penyintas';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: circleBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class CommunityCommentItem extends StatelessWidget {
  const CommunityCommentItem(this.comment, {super.key, required this.onAction});
  final Json comment;
  final ValueChanged<String> onAction;
  @override
  Widget build(BuildContext context) {
    final author = comment['author'] as Map;
    final authorName = author['display_name'] as String;
    final isOwn = comment['is_own'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: circleLightBlue,
                child: Text(
                  authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: circleBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: circleBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOwn ? 'Anda' : 'Pejuang',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      shortDate(comment['created_at']),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Pilihan komentar',
                icon: Icon(
                  Icons.more_horiz,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
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
          const SizedBox(height: 10),
          Text(
            comment['content'],
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.favorite_outline,
                size: 16,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
              Text(
                'Terbantu',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 16),
              Text(
                'Balas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: circleBlue,
                ),
              ),
            ],
          ),
          if (comment['moderation_status'] != 'approved')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                moderationLabel(comment['moderation_status']),
                style: const TextStyle(color: circleDeepBlue, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class CommunityTabBar extends StatelessWidget {
  const CommunityTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: circleSurface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        for (int i = 0; i < tabs.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected == i ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected == i
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected == i
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: selected == i ? circleBlue : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class CommunityFilterChips extends StatelessWidget {
  const CommunityFilterChips({
    super.key,
    required this.filters,
    required this.selected,
    required this.onChanged,
  });
  final List<String> filters;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: filters.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected == index ? circleBlue : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            filters[index],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected == index ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    ),
  );
}
