import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../chat/data/chat_api.dart';
import '../../../chat/domain/chat_models.dart';
import '../../../../shared/utils/error_helper.dart';

final _mensagemChatProvider = FutureProvider.autoDispose.family<ChatRoomModel, String>((ref, ministry) async {
  final api = ChatApi(ref.read(apiClientProvider));
  return api.findOrCreateMinistryRoom(ministry);
});

class MensagemPage extends ConsumerStatefulWidget {
  final bool isDark;
  final bool canCreate;

  const MensagemPage({super.key, required this.isDark, required this.canCreate});

  @override
  ConsumerState<MensagemPage> createState() => _MensagemPageState();
}

class _MensagemPageState extends ConsumerState<MensagemPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<ChatMessageModel> _messages = [];
  bool _loading = true;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages(String roomId) async {
    try {
      final api = ChatApi(ref.read(apiClientProvider));
      final msgs = await api.getMessages(roomId, limit: 100);
      if (mounted) setState(() { _messages = msgs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send(String roomId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    try {
      final api = ChatApi(ref.read(apiClientProvider));
      await api.sendMessage(roomId, text);
      await _loadMessages(roomId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final user = ref.watch(authProvider).user;
    final userId = user?.id ?? '';
    final roomAsync = ref.watch(_mensagemChatProvider('Louvor'));

    return roomAsync.when(
      data: (room) {
        if (_loading) _loadMessages(room.id);
        return Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Text('Nenhuma mensagem ainda',
                            style: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          reverse: true,
                          itemBuilder: (_, i) {
                            final msg = _messages[i];
                            final isMine = msg.senderId == userId;
                            return Align(
                              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMine
                                      ? const Color(0xFF008CFF)
                                      : (isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6)),
                                  borderRadius: BorderRadius.circular(20).copyWith(
                                    bottomRight: isMine ? const Radius.circular(4) : null,
                                    bottomLeft: !isMine ? const Radius.circular(4) : null,
                                  ),
                                ),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                child: Text(
                                  msg.content,
                                  style: TextStyle(
                                    color: isMine ? Colors.white : (isDark ? Colors.white : const Color(0xFF111827)),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161622) : Colors.white,
                border: Border(top: BorderSide(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB)),
                        ),
                        child: TextField(
                          controller: _msgCtrl,
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
                          decoration: InputDecoration(
                            hintText: 'Digite sua mensagem...',
                            hintStyle: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _send(room.id),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF008CFF),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Erro ao carregar bate-papo',
          style: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
      ),
    );
  }
}
