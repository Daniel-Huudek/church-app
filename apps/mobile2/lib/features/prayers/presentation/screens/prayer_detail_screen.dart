import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../providers/prayer_provider.dart';
import '../../domain/prayer_model.dart';

class PrayerDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const PrayerDetailScreen({super.key, required this.id});

  @override
  ConsumerState<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends ConsumerState<PrayerDetailScreen> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final insets = MediaQuery.of(context).padding;
    final state = ref.watch(prayerDetailProvider(widget.id));
    final p = state.prayer;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: state.loading
            ? Center(
                child: Text('Carregando...', style: TextStyle(color: t2)))
            : state.error != null && p == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(state.error!,
                          style: const TextStyle(color: Color(0xFFEF4444)),
                          textAlign: TextAlign.center),
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: Center(
                                    child: Text('←',
                                        style: TextStyle(fontSize: 28))),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: isDark ? 0.3 : 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: p!.isAnonymous
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF008CFF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            p.isAnonymous
                                                ? '??'
                                                : _initials(p.authorName),
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.isAnonymous
                                                  ? 'Anônimo'
                                                  : p.authorName,
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: t1)),
                                            const SizedBox(height: 2),
                                            Text(_formatDate(p.createdAt),
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: t2)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (p.title.isNotEmpty)
                                    Text(p.title,
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: t1)),
                                  if (p.title.isNotEmpty &&
                                      p.content.isNotEmpty)
                                    const SizedBox(height: 12),
                                  if (p.content.isNotEmpty)
                                    Text(p.content,
                                        style: TextStyle(
                                            fontSize: 15,
                                            height: 1.47,
                                            color: isDark
                                                ? const Color(0xFFD4D4D4)
                                                : const Color(0xFF374151))),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.only(top: 12),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: isDark
                                              ? const Color(0xFF1F2937)
                                              : const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _Stat(
                                            emoji: '🙏',
                                            count: p.reactionsCount,
                                            isDark: isDark),
                                        const SizedBox(width: 16),
                                        _Stat(
                                            emoji: '💬',
                                            count: p.commentsCount,
                                            isDark: isDark),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text('REAGIR',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: t2,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _PillBtn(
                                    iconPath: 'assets/icons/oracao.svg',
                                    label: 'Orando',
                                    isDark: isDark,
                                    onTap: () => ref
                                        .read(prayerDetailProvider(
                                                widget.id)
                                            .notifier)
                                        .toggleReaction('PRAYING')),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                                'COMENTÁRIOS (${state.comments.length})',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: t2,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 12),
                            if (state.error != null && p != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(state.error!,
                                    style: const TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 13),
                                    textAlign: TextAlign.center),
                              ),
                            if (state.comments.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: card,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text('Nenhum comentário ainda',
                                      style: TextStyle(color: t2)),
                                ),
                              )
                            else
                              ...state.comments.map(
                                (c) => _CommentTile(
                                    comment: c, isDark: isDark, card: card),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(
                            16, 12, 16, insets.bottom + 8),
                        decoration: BoxDecoration(
                          color: card,
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  controller: _commentCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Comentar...',
                                    hintStyle:
                                        TextStyle(color: t2, fontSize: 15),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: TextStyle(color: t1, fontSize: 15),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: state.posting
                                  ? null
                                  : () {
                                      final text = _commentCtrl.text;
                                      if (text.trim().isNotEmpty) {
                                        final user = ref
                                            .read(authProvider)
                                            .user;
                                        ref
                                            .read(prayerDetailProvider(
                                                    widget.id)
                                                .notifier)
                                            .addComment(
                                              text,
                                              userName: user?.name,
                                              userAvatar: user?.avatar,
                                            );
                                        _commentCtrl.clear();
                                      }
                                    },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF008CFF),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: state.posting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('→',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white)),
                                ),
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

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _formatDate(DateTime dt) {
    final months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _Stat extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isDark;

  const _Stat({required this.emoji, required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text('$count',
            style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))),
      ],
    );
  }
}

class _PillBtn extends StatelessWidget {
  final String? iconPath;
  final String emoji;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _PillBtn({
    this.iconPath,
    this.emoji = '',
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconPath != null
                ? SvgPicture.asset(iconPath!,
                    width: 16, height: 16,
                    colorFilter: ColorFilter.mode(
                      isDark
                          ? const Color(0xFFF9FAFB)
                          : const Color(0xFF111827),
                      BlendMode.srcIn,
                    ))
                : Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFF9FAFB)
                        : const Color(0xFF111827))),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final PrayerComment comment;
  final bool isDark;
  final Color card;

  const _CommentTile({
    required this.comment,
    required this.isDark,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF008CFF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(comment.authorName),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFF9FAFB)
                                : const Color(0xFF111827))),
                    const Spacer(),
                    Text(
                      _formatDate(comment.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content,
                    style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isDark
                            ? const Color(0xFFD4D4D4)
                            : const Color(0xFF374151))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _formatDate(DateTime dt) {
    final months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
