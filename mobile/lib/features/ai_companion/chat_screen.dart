import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/theme/theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
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
  @override
  void initState() {
    super.initState();
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
        .read(sessionProvider)
        .consents
        .contains('AI_CHAT_CONTEXT');
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: CareCard(
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: lavender,
                  child: Icon(Icons.favorite, color: hopelyBlue, size: 30),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, aku Hopi',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      Text('Teman tenang dan sahabat AI'),
                    ],
                  ),
                ),
                Chip(label: Text('24/7 Siaga'), backgroundColor: skySoft),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: CareCard(
            color: skySoft,
            padding: 14,
            radius: 18,
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, color: hopelyBlue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ruang aman tanpa penghakiman. Hopely bukan pengganti dokter atau psikolog.',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!allowed)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: CareCard(
              color: warningSoft,
              child: Column(
                children: [
                  Text(
                    'Izinkan penggunaan konteks AI sebelum memulai percakapan.',
                  ),
                  ActionLink('Atur izin AI', '/privacy'),
                ],
              ),
            ),
          ),
        if (metadata != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MockNotice(metadata),
          ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: scroll,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (messages.isEmpty)
                      const CareCard(
                        color: lavenderSoft,
                        child: Text(
                          'Aku di sini untuk mendengarkan. Apa yang ingin kamu ceritakan?',
                        ),
                      ),
                    for (final message in messages)
                      Align(
                        alignment: message['sender'] == 'user'
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 420),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: message['sender'] == 'user'
                                ? Colors.white
                                : skySoft,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(24),
                              topRight: const Radius.circular(24),
                              bottomLeft: Radius.circular(
                                message['sender'] == 'user' ? 24 : 6,
                              ),
                              bottomRight: Radius.circular(
                                message['sender'] == 'user' ? 6 : 24,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF25315F).withOpacity(0.06),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            message['content'],
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: ink,
                            ),
                          ),
                        ),
                      ),
                    if (busy) const LinearProgressIndicator(),
                    if (error != null) ErrorNotice(error!),
                  ],
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        enabled: allowed && !busy,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 4000,
                        decoration: const InputDecoration(
                          hintText: 'Ceritakan perasaanmu hari ini',
                          counterText: '',
                          prefixIcon: Icon(Icons.mic_none),
                          suffixIcon: Icon(Icons.mood_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: hopelyBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(56, 56),
                      ),
                      onPressed: allowed && !busy ? send : null,
                      icon: const Icon(Icons.send_outlined),
                      tooltip: 'Kirim pesan',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Percakapan pribadi, tanpa penilaian.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
