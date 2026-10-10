import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
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
                      padding: const EdgeInsets.all(20),
                      children: [
                        const CareCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: pillBlue,
                                    child: Icon(
                                      Icons.auto_awesome_outlined,
                                      color: hopelyBlue,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hopely AI',
                                          style: TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'Teman cerita & pendamping',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 14),
                              Text(
                                'Hopely AI mendampingi secara emosional, bukan pengganti dokter atau psikolog.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (!allowed)
                          const CareCard(
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
                        if (metadata != null) MockNotice(metadata),
                        if (messages.isEmpty)
                          const CareCard(
                            color: skySoft,
                            child: Text(
                              'Aku di sini untuk mendengarkan. Apa yang ingin kamu ceritakan?',
                            ),
                          ),
                        if (messages.isEmpty && allowed)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                label: const Text('Aku merasa cemas'),
                                onPressed: () => setState(
                                  () => input.text = 'Aku sedang merasa cemas.',
                                ),
                              ),
                              ActionChip(
                                label: const Text('Cerita hari ini'),
                                onPressed: () => setState(
                                  () => input.text =
                                      'Aku ingin bercerita tentang hari ini.',
                                ),
                              ),
                            ],
                          ),
                        for (final message in messages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: message['sender'] == 'user'
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['sender'] == 'user'
                                      ? 'Kamu'
                                      : 'Hopely AI',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: mutedInk,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: message['sender'] == 'user'
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 460,
                                    ),
                                    margin: EdgeInsets.only(
                                      left: message['sender'] == 'user'
                                          ? 28
                                          : 0,
                                      right: message['sender'] == 'user'
                                          ? 0
                                          : 20,
                                    ),
                                    padding: const EdgeInsets.all(19),
                                    decoration: BoxDecoration(
                                      color: message['sender'] == 'user'
                                          ? hopelyBlue
                                          : skySoft,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(22),
                                        topRight: const Radius.circular(22),
                                        bottomLeft: Radius.circular(
                                          message['sender'] == 'user' ? 22 : 5,
                                        ),
                                        bottomRight: Radius.circular(
                                          message['sender'] == 'user' ? 5 : 22,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      message['content'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.5,
                                        color: message['sender'] == 'user'
                                            ? Colors.white
                                            : ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                          hintText: 'Ketik ceritamu di sini…',
                          counterText: '',
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: hopelyBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(52, 52),
                      ),
                      onPressed: allowed && !busy ? send : null,
                      icon: const Icon(Icons.send_outlined),
                      tooltip: 'Kirim pesan',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
