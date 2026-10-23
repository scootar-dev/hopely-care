import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api.dart';
import '../../features/settings/profile_photo.dart';

class AccountAction extends ConsumerWidget {
  const AccountAction({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (MediaQuery.sizeOf(context).width < 1024) {
      return IconButton(
        tooltip: 'Buka Profil',
        onPressed: () => context.push('/profile'),
        icon: const ProfileAvatar(radius: 19),
      );
    }
    return PopupMenuButton<String>(
      tooltip: 'Menu akun',
      icon: const ProfileAvatar(radius: 19),
      onSelected: (value) async {
        if (value != 'logout') {
          context.push(value);
          return;
        }
        try {
          final session = ref.read(sessionProvider),
              api = ref.read(apiProvider);
          final device =
              session.deviceId ??
              await session.storage.read(key: 'hopely.device_id');
          if (device != null) await api.delete('/devices/$device');
          await api.post('/auth/logout');
          await session.storage.delete(key: 'hopely.device_id');
          await session.clear();
          if (context.mounted) context.go('/welcome');
        } catch (e) {
          if (context.mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            ref.read(sessionProvider).user?['name']?.toString() ?? 'Akun',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: '/profile', child: Text('Profil Saya')),
        const PopupMenuItem(value: '/profile', child: Text('Pengaturan')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'logout', child: Text('Keluar')),
      ],
    );
  }
}
