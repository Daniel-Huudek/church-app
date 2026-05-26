import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../chat/data/chat_api.dart';
import '../../../chat/domain/chat_models.dart';
import '../../../users/data/user_api.dart';
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
  Map<String, String> _userNames = {};
  Timer? _pollTimer;
  String? _roomId;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages(String roomId) async {
    _roomId = roomId;
    try {
      final api = ChatApi(ref.read(apiClientProvider));
      final msgs = await api.getMessages(roomId, limit: 100);
      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final ids = msgs.map((m) => m.senderId).toSet().where((id) => !_userNames.containsKey(id)).toList();
      if (ids.isNotEmpty) {
        try {
          final userApi = UserApi(ref.read(apiClientProvider));
          final users = await userApi.list(limit: ids.length);
          for (final u in users) {
            _userNames[u.id] = u.name;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() { _messages = msgs; _loading = false; });
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      }
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
      final user = ref.read(authProvider).user;
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

  void _startPolling(String roomId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadMessages(roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final user = ref.watch(authProvider).user;
    final userId = user?.id ?? '';
    final roomAsync = ref.watch(_mensagemChatProvider('Louvor'));

    return roomAsync.when(
      data: (room) {
        if (_loading) {
          _loadMessages(room.id);
          _startPolling(room.id);
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text('Bate-papo do Louvor',
                      style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: const Color(0xFF008CFF),
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _loadMessages(room.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Color(0xFF008CFF), size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) {
                            final msg = _messages[i];
                            final isMine = msg.senderId == userId;
                            final senderName = msg.senderName.isNotEmpty
                                ? msg.senderName
                                : _userNames[msg.senderId] ?? '...';
                            final showHeader = i == 0 || _messages[i - 1].senderId != msg.senderId;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (showHeader && !isMine) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(left: 44, bottom: 4),
                                      child: Text(senderName,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                                      ),
                                    ),
                                  ],
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isMine && showHeader)
                                        Container(
                                          width: 32, height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF008CFF).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Center(
                                            child: Text(
                                              senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                color: Color(0xFF008CFF), fontWeight: FontWeight.w700, fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      if (!isMine && showHeader) const SizedBox(width: 8),
                                      if (!isMine && !showHeader) const SizedBox(width: 40),
                                      Flexible(
                                        child: Container(
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
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.65,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                msg.content,
                                                style: TextStyle(
                                                  color: isMine ? Colors.white : (isDark ? Colors.white : const Color(0xFF111827)),
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatTime(msg.createdAt),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isMine ? Colors.white70 : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return 'há ${diff.inMinutes}min';
    if (diff.inDays < 1) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
