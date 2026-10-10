import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api.dart';
import '../../core/theme/theme.dart';

final photoPickerProvider = Provider<ImagePicker>((ref) => ImagePicker());
final recoveredPhotoProvider = StateProvider<XFile?>((ref) => null);
// Separate caches by account so a changed session never displays another photo.
final profilePhotoProvider = FutureProvider.autoDispose.family<Uint8List?, String>(
  (ref, userId) async {
    final data = await ref.read(apiProvider).get('/me/avatar');
    return data == null ? null : base64Decode(data['base64'] as String);
  },
);

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key, this.radius = 44});
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(sessionProvider.select((s) => s.user?['id'] as String?));
    final bytes = id == null ? null : ref.watch(profilePhotoProvider(id)).value;
    return CircleAvatar(
      radius: radius,
      backgroundColor: pillBlue,
      child: bytes == null
          ? Icon(Icons.person_outline, color: hopelyBlue, size: radius * 1.1)
          : ClipOval(
              child: Image.memory(
                bytes,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                semanticLabel: 'Foto profilmu',
                errorBuilder: (_, error, stack) => Icon(
                  Icons.person_outline,
                  color: hopelyBlue,
                  size: radius * 1.1,
                ),
              ),
            ),
    );
  }
}

class ProfilePhotoControls extends ConsumerStatefulWidget {
  const ProfilePhotoControls({super.key});

  @override
  ConsumerState<ProfilePhotoControls> createState() => _ProfilePhotoControlsState();
}

class _ProfilePhotoControlsState extends ConsumerState<ProfilePhotoControls> {
  bool busy = false;
  String? message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final recovered = ref.read(recoveredPhotoProvider);
      if (recovered == null) {
        return;
      }
      ref.read(recoveredPhotoProvider.notifier).state = null;
      await choosePhoto(recovered);
    });
  }

  Future<void> choosePhoto([XFile? recovered]) async {
    if (busy) {
      return;
    }
    final owner = ref.read(sessionProvider).user?['id'] as String?;
    if (owner == null) {
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final file = recovered ?? await ref.read(photoPickerProvider).pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (file == null) {
        return;
      }
      if (await file.length() > 2 * 1024 * 1024) {
        if (mounted) {
          setState(() => message = 'Pilih foto maksimal 2 MB.');
        }
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted || ref.read(sessionProvider).user?['id'] != owner) {
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Gunakan foto ini?'),
          content: ClipOval(
            child: Image.memory(
              bytes,
              width: 180,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => const SizedBox(
                width: 180,
                height: 180,
                child: Center(child: Text('Foto ini tidak dapat ditampilkan.')),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Simpan foto'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true || ref.read(sessionProvider).user?['id'] != owner) {
      return;
    }
      await ref.read(apiProvider).uploadProfilePhoto(bytes);
      if (!mounted) {
        return;
      }
      ref.invalidate(profilePhotoProvider(owner));
      setState(() => message = 'Foto profil berhasil diperbarui.');
    } catch (e) {
      if (mounted) {
        setState(() => message = friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> removePhoto() async {
    final owner = ref.read(sessionProvider).user?['id'] as String?;
    if (busy || owner == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus foto profil?'),
        content: const Text('Profilmu akan kembali menggunakan ikon bawaan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus foto'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || ref.read(sessionProvider).user?['id'] != owner) {
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await ref.read(apiProvider).delete('/me/avatar');
      if (!mounted) {
        return;
      }
      ref.invalidate(profilePhotoProvider(owner));
      setState(() => message = 'Foto profil dihapus.');
    } catch (e) {
      if (mounted) {
        setState(() => message = friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = ref.watch(sessionProvider.select((s) => s.user?['id'] as String?));
    final photo = id == null ? null : ref.watch(profilePhotoProvider(id));
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const ProfileAvatar(),
            Positioned(
              right: -8,
              bottom: -4,
              child: IconButton.filled(
                tooltip: 'Ubah foto profil',
                onPressed: busy ? null : () => choosePhoto(),
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: busy ? null : () => choosePhoto(),
              child: Text(busy ? 'Memproses foto…' : 'Pilih foto'),
            ),
            if (photo?.value != null)
              TextButton(
                onPressed: busy ? null : removePhoto,
                child: const Text('Hapus foto'),
              ),
          ],
        ),
        if (photo?.hasError == true)
          TextButton(
            onPressed: () => ref.invalidate(profilePhotoProvider(id!)),
            child: const Text('Foto belum dimuat. Coba lagi'),
          ),
        if (message != null) Text(message!, textAlign: TextAlign.center),
      ],
    );
  }
}
