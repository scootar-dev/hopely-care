import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api.dart';
import '../../../core/widgets/ui.dart';
import '../data/community_repository.dart';
import 'community_dialogs.dart';
import 'community_widgets.dart';

class CommunityPostDetailScreen extends ConsumerStatefulWidget {
  const CommunityPostDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<CommunityPostDetailScreen> createState() => _PostDetailState();
}

class _PostDetailState extends ConsumerState<CommunityPostDetailScreen> {
  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();
  int page = 1;
  bool busy = false;
  Object? error;
  String? notice;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> send(VoidCallback reload) async {
    if (busy) return;
    if (_commentController.text.trim().length < 2) {
      setState(() => notice = 'Tulis komentar minimal 2 karakter.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      notice = null;
    });
    try {
      final result = await ref
          .read(communityRepositoryProvider)
          .comment(widget.id, _commentController.text.trim());
      if (!mounted) return;
      _commentController.clear();
      setState(() {
        notice = result['moderation_status'] == 'approved'
            ? 'Komentar berhasil dibagikan.'
            : 'Komentar tersimpan dan menunggu peninjauan moderator.';
      });
      reload();
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
      title: 'Detail Cerita Dan Diskusi',
      body: DataPage(
        key: ValueKey(page),
        load: () async {
          final data = await Future.wait([
            repo.post(widget.id),
            repo.comments(widget.id, page: page),
          ]);
          return {'post': data[0], 'comments': data[1]};
        },
        builder: (data, reload) {
          final post = Map<String, dynamic>.from(data['post']);
          final comments = Map<String, dynamic>.from(data['comments']);
          final canParticipate = post['can_participate'] == true;
          return Stack(
            children: [
              // Main scrollable content
              CommunityBody(
                children: [
                  // Top badge + menu row
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: circleBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Ruang Berbagi',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: circleBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Options menu
                        _PostOptionMenu(
                          post: post,
                          repo: repo,
                          onChanged: reload,
                        ),
                      ],
                    ),
                  ),
                  // Post detail card
                  _PostDetailCard(
                    post: post,
                    onChanged: reload,
                    onComment: canParticipate
                        ? () => _commentFocus.requestFocus()
                        : null,
                  ),
                  // Safety note
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: circleSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield, size: 18, color: circleBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Interaksi dipantau tim pendamping Hopely demi kenyamanan bersama.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Comments header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Dukungan Hangat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0B1C30),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${post['comment_count'] ?? 0} Komentar)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: circleBlue,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Terbaru',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Comments list
                  if (items(comments).isEmpty)
                    const CommunityEmptyState(
                      'Belum ada komentar',
                      'Sapaan hangat bisa menjadi awal dukungan.',
                    ),
                  for (final c in items(comments))
                    _CommentCard(
                      comment: c,
                      onAction: (action) async {
                        if (await communityContentAction(
                              context,
                              repo,
                              action,
                              'comment',
                              c,
                            ) &&
                            mounted) {
                          reload();
                        }
                      },
                    ),
                  CommunityPagination(
                    comments,
                    (v) => setState(() => page = v),
                  ),

                  // Extra bottom padding for comment input
                  if (!canParticipate)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Text(
                        'Komentar tersedia untuk anggota pada cerita yang sudah diterbitkan.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  if (notice != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: circleSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notice!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: circleDeepBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (error != null) ErrorNotice(error!),
                  if (canParticipate) const SizedBox(height: 100),
                ],
              ),
              // Sticky comment input at bottom (only if can participate)
              if (canParticipate)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .95),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FF),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    key: const Key('community-comment-content'),
                                    controller: _commentController,
                                    focusNode: _commentFocus,
                                    enabled: !busy,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Tulis kata-kata penyemangat...',
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade400,
                                      ),
                                      border: InputBorder.none,
                                      filled: false,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                    onSubmitted: (_) => send(reload),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Icon(
                                    Icons.sentiment_satisfied_outlined,
                                    size: 22,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Send button
                        Semantics(
                          button: true,
                          label: 'Kirim komentar',
                          child: Material(
                            color: circleBlue,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: busy ? null : () => send(reload),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: busy
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PostDetailCard extends ConsumerStatefulWidget {
  const _PostDetailCard({
    required this.post,
    required this.onChanged,
    this.onComment,
  });
  final VoidCallback? onComment;
  final Json post;
  final VoidCallback onChanged;

  @override
  ConsumerState<_PostDetailCard> createState() => _PostDetailCardState();
}

class _PostDetailCardState extends ConsumerState<_PostDetailCard> {
  late Json post = widget.post;
  bool busy = false;
  Object? error;

  @override
  void didUpdateWidget(covariant _PostDetailCard oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final author = post['author'] as Map;
    final authorName = author['display_name'] as String;
    final reactionCount = post['reaction_count'] as int? ?? 0;
    final commentCount = post['comment_count'] as int? ?? 0;

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
          // Author header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFDBEAFE),
                child: Text(
                  authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: circleBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          authorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B1C30),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 18, color: circleBlue),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Penyintas Kanker • ${shortDate(post['created_at'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Community tag
          if (post['community_name'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5EEFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                post['community_name'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: circleBlue,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Post content
          Text(
            post['content'] as String,
            style: const TextStyle(
              fontSize: 15,
              height: 1.65,
              color: Color(0xFF0B1C30),
            ),
          ),
          if (post['moderation_status'] != null &&
              post['moderation_status'] != 'approved') ...[
            const SizedBox(height: 8),
            Text(
              moderationLabel(post['moderation_status']),
              style: const TextStyle(
                color: circleDeepBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          // Image if present
          if (error != null) ErrorNotice(error!),
          if (post['has_image'] == true)
            CommunityImage(post['id'], revision: post['revision']),
          const SizedBox(height: 16),
          CommunityReactionBar(
            selected: post['my_reaction'] as String?,
            count: reactionCount,
            commentCount: commentCount,
            onReact: !busy && post['can_participate'] == true ? react : null,
            onComment: widget.onComment,
          ),
        ],
      ),
    );
  }
}

class _PostOptionMenu extends StatelessWidget {
  const _PostOptionMenu({
    required this.post,
    required this.repo,
    required this.onChanged,
  });
  final Json post;
  final CommunityRepository repo;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final own = post['is_own'] == true;
    return PopupMenuButton<String>(
      tooltip: 'Pilihan cerita',
      icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (action) async {
        final changed = await communityContentAction(
          context,
          repo,
          action,
          'post',
          post,
        );
        if (changed) onChanged();
      },
      itemBuilder: (_) => [
        if (own && post['moderation_status'] != 'removed')
          const PopupMenuItem(value: 'edit', child: Text('Edit cerita')),
        if (own)
          const PopupMenuItem(value: 'delete', child: Text('Hapus cerita')),
        if (!own)
          const PopupMenuItem(
            value: 'report',
            child: Text(
              'Laporkan cerita',
              style: TextStyle(color: Color(0xFFBA1A1A)),
            ),
          ),
        if (!own)
          const PopupMenuItem(value: 'block', child: Text('Blokir pengguna')),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, required this.onAction});
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
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFDBEAFE),
                child: Text(
                  authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: circleBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          authorName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Role badge
                        _RoleBadge(isOwn: isOwn),
                        const Spacer(),
                        Text(
                          shortDate(comment['created_at']),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comment['content'] as String,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: 10),
                    // Like + Reply row
                    Row(
                      children: [
                        InkWell(
                          onTap: () {},
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite_outline,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Terbantu (${(comment['helpful_count'] ?? 0)})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
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
                    if (comment['moderation_status'] != 'approved') ...[
                      const SizedBox(height: 6),
                      Text(
                        moderationLabel(comment['moderation_status']),
                        style: const TextStyle(
                          color: circleDeepBlue,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  size: 18,
                  color: Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                      child: Text('Laporkan'),
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
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isOwn});
  final bool isOwn;
  @override
  Widget build(BuildContext context) {
    if (isOwn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFDBEAFE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Anda',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: circleBlue,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.health_and_safety_outlined, size: 11, color: circleBlue),
          SizedBox(width: 3),
          Text(
            'Pejuang',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: circleBlue,
            ),
          ),
        ],
      ),
    );
  }
}
