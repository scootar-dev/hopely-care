import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/api.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/widgets/stitch.dart';
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
      title: postId == null ? 'Tulis Cerita Harapan' : 'Edit Cerita',
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
  final _contentController = TextEditingController();
  late String communityId;
  Uint8List? image;
  bool busy = false, picking = false;
  Object? error;
  String? photoError;
  final Set<String> _selectedTags = {};
  final _tags = const ['#TipsPemulihan', '#TanyaJawab', '#SemangatKemo', '#NutrisiSehat', '#CatatanHati'];
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    final requested =
        widget.post?['community_id'] as String? ?? widget.initialCommunity;
    communityId = widget.communities.any((c) => c['id'] == requested)
        ? requested!
        : widget.communities.first['id'];
    _contentController.text = widget.post?['content'] as String? ?? '';
    _charCount = _contentController.text.length;
    _contentController.addListener(() {
      setState(() => _charCount = _contentController.text.length);
    });
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
                'Foto dipulihkan sebagai pratinjau. Periksa kembali cerita sebelum berbagi.';
          });
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
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
    if (_contentController.text.trim().length < 2) {
      setState(() => error = 'Tulis cerita minimal 2 karakter.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = widget.post == null
          ? await widget.repo.create(communityId, _contentController.text.trim(), image)
          : await widget.repo.edit(widget.post!, _contentController.text.trim());
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
  Widget build(BuildContext context) {
    return CommunityBody(
      children: [
        // Sanctuary header note
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: circleSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: HopelyMark(size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ruang Teduh Berbagi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                    Text(
                      'Suaramu bermakna bagi sesama pejuang dan pendamping.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Main form card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
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
              // Community selector
              const Text(
                'Tujuan Komunitas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF434655),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: circleSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: communityId,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(12),
                    items: widget.communities
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c['id'] as String,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: circleBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    c['name'] as String,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: busy || widget.post != null
                        ? null
                        : (v) => setState(() => communityId = v!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Text area
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Isi Catatan Hati',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF434655),
                    ),
                  ),
                  Text(
                    '$_charCount/1000',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: circleSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      key: const Key('community-post-content'),
                      controller: _contentController,
                      enabled: !busy,
                      minLines: 7,
                      maxLines: 14,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        hintText:
                            'Apa yang ingin kamu bagikan? Ceritakan perasaan, pertanyaan seputar perawatan, atau secercah harapan hari ini...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                          height: 1.5,
                        ),
                        border: InputBorder.none,
                        filled: false,
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 14, height: 1.65),
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.favorite_outline, size: 16, color: circleBlue),
                        const SizedBox(width: 6),
                        Text(
                          'Suasana aman & saling menopang',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Photo attachment
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
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
              const Text(
                'Lampiran Gambar (Opsional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF434655),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Add photo button
                  if (widget.post == null)
                    GestureDetector(
                      onTap: busy || picking ? null : pickImage,
                      child: Container(
                        width: 112,
                        height: 80,
                        decoration: BoxDecoration(
                          color: circleSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: circleSurface),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: picking ? Colors.grey : circleBlue,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              picking ? 'Membuka...' : 'Tambah Foto',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: picking ? Colors.grey : circleBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Image preview
                  if (image != null) ...[
                    const SizedBox(width: 12),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            image!,
                            width: 112,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, stack) => const Text('Format tidak didukung'),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: busy ? null : () => setState(() => image = null),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              if (photoError != null) ...[
                const SizedBox(height: 8),
                Text(photoError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              if (image != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Pastikan semua orang dalam foto setuju untuk membagikannya. Foto ditinjau moderator sebelum terbit.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),
        // Topic tags
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
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
              const Text(
                'Pilih Topik Terkait',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF434655),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? circleBlue : const Color(0xFFDDE1FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF001453),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        // Safety notice
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: circleSurface,
            borderRadius: BorderRadius.circular(14),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ruang ini dijaga bersama',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mohon hindari membagikan data rekam medis sensitif (NIK/Nomor Rekam Medis) atau promosi obat tanpa anjuran dokter.',
                      style: TextStyle(
                        fontSize: 12,
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
        if (error != null) ErrorNotice(error!),
        // Primary CTA - Bagikan
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: busy || picking ? null : publish,
            style: FilledButton.styleFrom(
              backgroundColor: circleBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_outlined, size: 20),
            label: Text(
              busy
                  ? 'Menyimpan cerita…'
                  : widget.post == null
                  ? 'Bagikan'
                  : 'Simpan Perubahan',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary CTA - Batal/Simpan Draf
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton.icon(
            onPressed: busy ? null : () => context.pop(),
            icon: const Icon(Icons.bookmark_border, size: 18),
            label: const Text('Batal / Simpan Draf'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade500,
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
