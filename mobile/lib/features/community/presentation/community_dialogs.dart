import 'package:flutter/material.dart';
import '../../../core/api/api.dart';
import '../../../core/widgets/ui.dart';
import '../data/community_repository.dart';
import 'community_widgets.dart';

Future<bool> communityConfirm(
  BuildContext context,
  String title,
  String message,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

Future<bool> communityContentAction(
  BuildContext context,
  CommunityRepository repo,
  String action,
  String type,
  Json item,
) async {
  if (action == 'report') {
    return await showDialog<bool>(
          context: context,
          builder: (_) => _ReportDialog(repo, type, item['id']),
        ) ??
        false;
  }
  final block = action == 'block';
  if (!await communityConfirm(
    context,
    block
        ? 'Blokir pengguna ini?'
        : 'Hapus ${type == 'post' ? 'cerita' : 'komentar'}?',
    block
        ? 'Kalian tidak akan melihat cerita dan komentar satu sama lain. Kamu dapat membuka blokir di Keamanan Komunitas. Moderator tetap dapat meninjau konten yang dilaporkan.'
        : 'Konten ini akan dihapus dari komunitas.',
    block ? 'Blokir' : 'Hapus',
  )) {
    return false;
  }
  try {
    if (block) {
      await repo.block(item['author']['id']);
    } else if (type == 'post') {
      await repo.deletePost(item['id']);
    } else {
      await repo.deleteComment(item['id']);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(block ? 'Pengguna diblokir.' : 'Konten dihapus.'),
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
    return false;
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog(this.repo, this.type, this.id);
  final CommunityRepository repo;
  final String type, id;
  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final description = TextEditingController();
  String reason = 'misinformation';
  bool busy = false;
  Object? error;
  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  Future<void> send() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repo.report(
        widget.type,
        widget.id,
        reason,
        description.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan diterima untuk ditinjau moderator.'),
          ),
        );
        Navigator.pop(context, true);
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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Laporkan konten'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Identitas pelapor tidak ditampilkan kepada penulis cerita.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: reason,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Alasan laporan'),
            items: reportReasons.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: busy ? null : (v) => setState(() => reason = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            maxLength: 1000,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Keterangan (opsional)',
            ),
          ),
          if (error != null) ErrorNotice(error!),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: busy ? null : send,
        child: Text(busy ? 'Mengirim…' : 'Kirim laporan'),
      ),
    ],
  );
}

Future<bool> showCommunityJoin(
  BuildContext context,
  CommunityRepository repo,
  Json community,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => _JoinDialog(repo, community),
      ) ??
      false;
}

class _JoinDialog extends StatefulWidget {
  const _JoinDialog(this.repo, this.community);
  final CommunityRepository repo;
  final Json community;
  @override
  State<_JoinDialog> createState() => _JoinDialogState();
}

class _JoinDialogState extends State<_JoinDialog> {
  final name = TextEditingController();
  final form = GlobalKey<FormState>();
  bool accepted = false, busy = false;
  Object? error;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> join() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repo.join(widget.community['id'], name.text.trim());
      if (mounted) Navigator.pop(context, true);
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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Bergabung dengan komunitas'),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.community['name'],
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pilih nama yang terlihat di semua komunitasmu. Email, foto profil pribadi, dan catatan kesehatanmu tidak ikut dibagikan.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: name,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Nama di komunitas'),
              validator: (v) => (v?.trim().length ?? 0) < 2
                  ? 'Isi nama minimal 2 karakter.'
                  : null,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: accepted,
              onChanged: busy ? null : (v) => setState(() => accepted = v!),
              title: const Text(
                'Saya setuju berbagi dengan hormat, menjaga privasi, dan tidak memberi diagnosis atau resep.',
              ),
            ),
            if (error != null) ErrorNotice(error!),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: accepted && !busy ? join : null,
        child: Text(busy ? 'Bergabung…' : 'Gabung sekarang'),
      ),
    ],
  );
}
