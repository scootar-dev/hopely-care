import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/widgets/stitch.dart';
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
  final comment = TextEditingController();
  int page = 1;
  bool accepted = false, busy = false;
  Object? error;
  String? notice;
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> send(VoidCallback reload) async {
    if (comment.text.trim().length < 2) {
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
          .comment(widget.id, comment.text.trim());
      if (!mounted) return;
      comment.clear();
      setState(() {
        accepted = false;
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
      title: 'Cerita & Dukungan',
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
          return CommunityBody(
            children: [
              CommunityPostCard(post, detail: true, onChanged: reload),
              const CommunitySafetyBanner(),
              const SectionHeading('Saling menguatkan'),
              if (items(comments).isEmpty)
                const CommunityEmptyState(
                  'Belum ada komentar',
                  'Sapaan hangat bisa menjadi awal dukungan.',
                ),
              for (final c in items(comments))
                CommunityCommentItem(
                  c,
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
              CommunityPagination(comments, (v) => setState(() => page = v)),
              if (post['can_participate'] == true)
                CareCard(
                  child: Column(
                    children: [
                      TextField(
                        key: const Key('community-comment-content'),
                        controller: comment,
                        enabled: !busy,
                        minLines: 2,
                        maxLines: 5,
                        maxLength: 4000,
                        decoration: const InputDecoration(
                          labelText: 'Tulis dukunganmu',
                          hintText: 'Terima kasih sudah berbagi…',
                        ),
                      ),
                      CheckboxListTile(
                        key: const Key('community-comment-consent'),
                        contentPadding: EdgeInsets.zero,
                        value: accepted,
                        onChanged: busy
                            ? null
                            : (v) => setState(() => accepted = v!),
                        title: const Text(
                          'Saya setuju membagikan dan memoderasi komentar ini.',
                        ),
                        subtitle: const Text(
                          'Teks dapat diperiksa oleh layanan AI jika aktif dan moderator.',
                        ),
                      ),
                      if (error != null) ErrorNotice(error!),
                      FilledButton(
                        onPressed: !busy && accepted
                            ? () => send(reload)
                            : null,
                        child: Text(busy ? 'Mengirim…' : 'Kirim dukungan'),
                      ),
                    ],
                  ),
                )
              else
                const CareCard(
                  child: Text(
                    'Komentar tersedia untuk anggota pada cerita yang sudah diterbitkan.',
                  ),
                ),
              if (notice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    notice!,
                    style: const TextStyle(color: circleDeepBlue),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
