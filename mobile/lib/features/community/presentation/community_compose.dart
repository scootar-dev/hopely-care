import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/api.dart';
import '../../../core/widgets/ui.dart';
import '../data/community_repository.dart';
import '../data/community_photo.dart';
import 'community_widgets.dart';

class CommunityComposeScreen extends ConsumerWidget {
  const CommunityComposeScreen({super.key, this.communityId, this.postId});
  final String? communityId, postId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(communityRepositoryProvider);
    return CommunityScaffold(
      title: postId == null ? 'Bagikan Cerita' : 'Edit Cerita',
      body: DataPage(
        load: () async => {
          'memberships': await repo.allMemberships(),
          'post': postId == null ? null : await repo.post(postId!),
        },
        builder: (data, reload) {
          final communities = items(
            data['memberships'],
          ).where((c) => c['membership_status'] == 'active').toList();
          if (communities.isEmpty) {
            return CommunityBody(
              children: [
                CommunityEmptyState(
                  'Pilih ruangmu terlebih dahulu',
                  'Kamu perlu bergabung sebelum membagikan cerita.',
                  action: FilledButton(
                    onPressed: () async {
                      await context.push('/community/discover');
                      if (context.mounted) reload();
                    },
                    child: const Text('Temukan komunitas'),
                  ),
                ),
              ],
            );
          }
          return _ComposeForm(
            repo: repo,
            communities: communities,
            initialCommunity: communityId,
            post: data['post'] as Json?,
          );
        },
      ),
    );
  }
}

class _ComposeForm extends ConsumerStatefulWidget {
  const _ComposeForm({
    required this.repo,
    required this.communities,
    this.initialCommunity,
    this.post,
  });
  final CommunityRepository repo;
  final List<Json> communities;
  final String? initialCommunity;
  final Json? post;
  @override
  ConsumerState<_ComposeForm> createState() => _ComposeFormState();
}

class _ComposeFormState extends ConsumerState<_ComposeForm> {
  final form = GlobalKey<FormState>();
  final content = TextEditingController();
  late String communityId;
  Uint8List? image;
  bool accepted = false, busy = false, picking = false;
  Object? error;
  String? photoError;
  @override
  void initState() {
    super.initState();
    final requested =
        widget.post?['community_id'] as String? ?? widget.initialCommunity;
    communityId = widget.communities.any((c) => c['id'] == requested)
        ? requested!
        : widget.communities.first['id'];
    content.text = widget.post?['content'] as String? ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final recovered = ref.read(recoveredCommunityPhotoProvider);
      if (recovered == null) return;
      ref.read(recoveredCommunityPhotoProvider.notifier).state = null;
      if (recovered.userId != widget.repo.api.session.user?['id'] ||
          recovered.communityId != communityId) {
        return;
      }
      try {
        final bytes = await recovered.file.readAsBytes();
        if (mounted && bytes.length <= 2 * 1024 * 1024) {
          setState(() {
            image = bytes;
            photoError =
                'Foto dipulihkan sebagai pratinjau. Periksa kembali cerita dan persetujuan sebelum berbagi.';
          });
        }
      } catch (_) {
        /* A fresh gallery selection remains available. */
      }
    });
  }

  @override
  void dispose() {
    content.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    setState(() {
      picking = true;
      photoError = null;
    });
    try {
      final session = widget.repo.api.session;
      await session.storage.write(
        key: communityPhotoIntentKey,
        value: jsonEncode({
          'user_id': session.user?['id'],
          'community_id': communityId,
        }),
      );
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 2 * 1024 * 1024) {
        setState(() => photoError = 'Pilih foto maksimal 2 MB.');
        return;
      }
      setState(() => image = bytes);
    } catch (_) {
      if (mounted) {
        setState(
          () => photoError =
              'Galeri belum dapat dibuka. Periksa izin foto dan coba lagi.',
        );
      }
    } finally {
      try {
        await widget.repo.api.session.storage.delete(
          key: communityPhotoIntentKey,
        );
      } catch (_) {}
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> publish() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = widget.post == null
          ? await widget.repo.create(communityId, content.text.trim(), image)
          : await widget.repo.edit(widget.post!, content.text.trim());
      if (!mounted) return;
      final approved = result['moderation_status'] == 'approved';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? 'Cerita berhasil dibagikan.'
                : 'Cerita tersimpan. Moderator perlu meninjaunya sebelum terbit.',
          ),
        ),
      );
      if (widget.post != null) {
        context.pop();
      } else {
        context.pushReplacement('/community/posts/${result['id']}');
      }
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
  Widget build(BuildContext context) => Form(
    key: form,
    child: CommunityBody(
      children: [
        const Heading(
          'Ceritamu berarti.',
          'Bagikan secukupnya, dengan caramu sendiri.',
        ),
        const CommunitySafetyBanner(sharing: true),
        CareCard(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: communityId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Bagikan ke komunitas',
                ),
                items: widget.communities
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text(
                          c['name'] as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: busy || widget.post != null
                    ? null
                    : (v) => setState(() => communityId = v!),
              ),
              const SizedBox(height: 18),
              TextFormField(
                key: const Key('community-post-content'),
                controller: content,
                enabled: !busy,
                minLines: 7,
                maxLines: 14,
                maxLength: 4000,
                decoration: const InputDecoration(
                  labelText: 'Apa yang ingin kamu ceritakan?',
                  alignLabelWithHint: true,
                  hintText:
                      'Sebuah perasaan, langkah kecil, atau dukungan untuk teman seperjalanan…',
                ),
                validator: (v) => (v?.trim().length ?? 0) < 2
                    ? 'Tulis cerita minimal 2 karakter.'
                    : null,
              ),
              if (widget.post == null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: busy || picking ? null : pickImage,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      image == null ? 'Tambah foto (opsional)' : 'Ganti foto',
                    ),
                  ),
                ),
              if (image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.memory(
                    image!,
                    height: 190,
                    fit: BoxFit.contain,
                    errorBuilder: (_, e, stack) => const Text(
                      'Format foto tidak dapat ditampilkan. Silakan ganti foto.',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: busy ? null : () => setState(() => image = null),
                  child: const Text('Hapus foto pilihan'),
                ),
                const Text(
                  'Pastikan semua orang dalam foto setuju untuk membagikannya. Foto ditinjau moderator sebelum terbit.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
              if (widget.post?['has_image'] == true)
                const Text(
                  'Foto yang sudah dilampirkan tetap disertakan dan ditinjau kembali.',
                ),
              if (photoError != null)
                Text(photoError!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
        CheckboxListTile(
          key: const Key('community-sharing-consent'),
          contentPadding: EdgeInsets.zero,
          value: accepted,
          onChanged: busy ? null : (v) => setState(() => accepted = v!),
          title: const Text(
            'Saya memilih membagikan isi ini dengan nama komunitas saya.',
          ),
          subtitle: const Text(
            'Teks diperiksa sistem moderasi, termasuk layanan AI jika aktif, dan dapat ditinjau moderator. Jurnal dan chat pribadi tidak ikut dibagikan.',
          ),
        ),
        const SizedBox(height: 16),
        if (error != null) ErrorNotice(error!),
        FilledButton.icon(
          onPressed: accepted && !busy && !picking ? publish : null,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_outlined),
          label: Text(
            busy
                ? 'Menyimpan cerita…'
                : widget.post == null
                ? 'Bagikan Cerita'
                : 'Simpan Perubahan',
          ),
        ),
      ],
    ),
  );
}
