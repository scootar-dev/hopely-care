import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';
import '../../core/theme/theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.initialPrompt});
  final String? initialPrompt;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final input = TextEditingController(), scroll = ScrollController();
  final List<Json> messages = [];
  String? sessionId;
  bool busy = false, loading = true;
  Object? error;
  dynamic metadata;
  Future<void> chooseSession() async {
    try {
      final sessions = items(await ref.read(apiProvider).get('/chat/sessions'));
      if (!mounted) return;
      final selected = await showModalBottomSheet<Json>(
        context: context,
        builder: (c) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Percakapan tersimpan')),
              if (sessions.isEmpty)
                const ListTile(title: Text('Belum ada percakapan.')),
              for (final s in sessions)
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(s['title'] ?? 'Percakapan'),
                  subtitle: Text('${s['created_at']}'),
                  onTap: () => Navigator.pop(c, s),
                ),
            ],
          ),
        ),
      );
      if (selected == null || !mounted) return;
      setState(() => loading = true);
      final rows = items(
        await ref
            .read(apiProvider)
            .get('/chat/sessions/${selected['id']}/messages'),
      );
      if (mounted) {
        setState(() {
          sessionId = selected['id'];
          messages
            ..clear()
            ..addAll(rows);
          metadata = null;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    input.text = widget.initialPrompt == 'anxiety'
        ? 'Aku sedang merasa cemas.'
        : widget.initialPrompt == 'story'
        ? 'Aku ingin bercerita tentang hari ini.'
        : '';
    load();
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final api = ref.read(apiProvider);
      final sessions = items(await api.get('/chat/sessions'));
      if (sessions.isNotEmpty) {
        sessionId = sessions.first['id'];
        messages.addAll(
          items(await api.get('/chat/sessions/$sessionId/messages')),
        );
      }
    } catch (e) {
      error = e;
    }
    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> send() async {
    if (input.text.trim().isEmpty) {
      return;
    }
    final text = input.text.trim();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await ref.read(apiProvider).post('/ai/chat', {
        'message': text,
        if (sessionId != null) 'session_id': sessionId,
      });
      if (!mounted) {
        return;
      }
      setState(() {
        sessionId = result['session_id'];
        metadata = result['metadata'];
        messages.add({'sender': 'user', 'content': text});
        messages.add({
          'sender': 'assistant',
          'content': result['reply'],
          'safety_level': result['safety_signal'],
        });
        input.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) {
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => error = e);
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = ref
        .watch(sessionProvider)
        .consents
        .contains('AI_CHAT_CONTEXT');
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          children: [
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      children: [
                        Row(
                          children: [
                            const HopelyMark(size: 52),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hopely AI',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: ink,
                                    ),
                                  ),
                                  Text('Hadir mendengarkan'),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => context.push('/chat/voice'),
                              icon: const Icon(Icons.mic_none_outlined),
                              tooltip: 'Mode suara',
                            ),
                            IconButton(
                              tooltip: 'Riwayat percakapan',
                              icon: const Icon(Icons.history),
                              onPressed: busy ? null : chooseSession,
                            ),
                            IconButton(
                              tooltip: 'Percakapan baru',
                              icon: const Icon(Icons.add_comment_outlined),
                              onPressed: busy
                                  ? null
                                  : () => setState(() {
                                      sessionId = null;
                                      messages.clear();
                                      metadata = null;
                                      error = null;
                                      input.clear();
                                    }),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonalIcon(
                            onPressed: () => setState(
                              () => input.text =
                                  'Boleh, pandu aku hening 2 menit.',
                            ),
                            icon: const Icon(Icons.air, size: 18),
                            label: const Text('Latihan Napas'),
                            style: FilledButton.styleFrom(
                              backgroundColor: skySoft,
                              foregroundColor: hopelyBlue,
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!allowed)
                          const CareCard(
                            color: warningSoft,
                            padding: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Izinkan penggunaan konteks AI sebelum memulai percakapan.',
                                ),
                                SizedBox(height: 4),
                                ActionLink('Atur izin AI', '/privacy'),
                              ],
                            ),
                          ),
                        if (metadata != null) MockNotice(metadata),
                        if (messages.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Center(
                              child: SoftLabel(
                                'Percakapan tersimpan',
                                icon: Icons.lock_outline,
                              ),
                            ),
                          ),
                        if (!allowed)
                          const SizedBox.shrink()
                        else if (messages.isEmpty)
                          const _AssistantBubble(
                            text:
                                'Aku di sini untuk mendengarkan. Apa yang ingin kamu ceritakan?',
                          ),
                        if (messages.isEmpty && allowed)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _PromptChip(
                                icon: Icons.self_improvement,
                                label: 'Boleh, pandu aku hening 2 menit',
                                onPressed: () => setState(
                                  () => input.text =
                                      'Boleh, pandu aku hening 2 menit.',
                                ),
                              ),
                              _PromptChip(
                                icon: Icons.psychology_alt_outlined,
                                label: 'Tips meredakan mual & lemas',
                                onPressed: () => setState(
                                  () => input.text =
                                      'Ceritakan caraku meredakan mual pasca infus.',
                                ),
                              ),
                              _PromptChip(
                                icon: Icons.sentiment_satisfied_alt_outlined,
                                label: 'Aku hanya ingin bercerita',
                                onPressed: () => setState(
                                  () => input.text =
                                      'Aku ingin sekadar bercerita saja.',
                                ),
                              ),
                            ],
                          ),
                        for (final message in messages)
                          _ChatBubble(message: message),
                        if (busy) const LinearProgressIndicator(),
                        if (error != null) ErrorNotice(error!),
                      ],
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: hopelyCardShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: input,
                          enabled: allowed && !busy,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 4000,
                          decoration: const InputDecoration(
                            hintText: 'Tulis apa yang dirasakan saat ini...',
                            counterText: '',
                            fillColor: Colors.transparent,
                            filled: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: hopelyBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: allowed && !busy ? send : null,
                        icon: const Icon(Icons.arrow_upward),
                        tooltip: 'Kirim pesan',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 15, color: tertiaryInk),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Hopely bukan pengganti tenaga kesehatan.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: 17, color: hopelyBlue),
    label: Text(label),
    onPressed: onPressed,
    backgroundColor: Colors.white,
    side: BorderSide.none,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  );
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) =>
      _ChatBubble(message: {'sender': 'assistant', 'content': text});
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final Json message;
  @override
  Widget build(BuildContext context) {
    final user = message['sender'] == 'user';
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: user ? hopelyBlue : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: Radius.circular(user ? 22 : 6),
          bottomRight: Radius.circular(user ? 6 : 22),
        ),
        boxShadow: user ? null : hopelyCardShadow,
      ),
      child: Text(
        message['content'],
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: user ? Colors.white : ink,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: user
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!user) ...[
            const IconWell(
              Icons.favorite_outline,
              size: 42,
              radius: 21,
              background: Colors.white,
            ),
            const SizedBox(width: 12),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}
