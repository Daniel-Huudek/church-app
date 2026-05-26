import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/prayer_model.dart';
import 'stat_widget.dart';
import 'reaction_button.dart';

class PrayerCard extends StatefulWidget {
  final PrayerModel prayer;
  final bool isDark;
  final int index;
  final String currentUserId;
  final bool isAdmin;
  final VoidCallback onTap;
  final void Function(String type) onReact;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PrayerCard({
    required this.prayer,
    required this.isDark,
    required this.index,
    required this.currentUserId,
    this.isAdmin = false,
    required this.onTap,
    required this.onReact,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _slideAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _initials {
    final name = widget.prayer.authorName;
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prayer;
    final isDark = widget.isDark;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Opacity(
        opacity: _opacityAnim.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: p.isUrgent
                  ? Border.all(color: const Color(0xFFEF4444), width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.isUrgent)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('URGENTE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1)),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: p.isAnonymous
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF008CFF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          p.isAnonymous ? '??' : _initials,
                          style: const TextStyle(
                              fontSize: 12,
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
                          Text(
                            p.isAnonymous ? 'Anônimo' : p.authorName,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFF9FAFB)
                                    : const Color(0xFF111827)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(p.createdAt),
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p.categoryName != null)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF008CFF).withValues(alpha: 0.13)
                                  : const Color(0xFF008CFF).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(p.categoryName!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF008CFF),
                                    fontWeight: FontWeight.w600)),
                          ),
                        if (p.authorId == widget.currentUserId || widget.isAdmin)
                          _actionBtn(Icons.edit_outlined, widget.onEdit),
                        if (p.authorId == widget.currentUserId || widget.isAdmin)
                          _actionBtn(Icons.delete_outline, widget.onDelete),
                      ],
                    ),
                  ],
                ),
                if (p.title.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(p.title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFF9FAFB)
                              : const Color(0xFF111827))),
                ],
                if (p.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(p.content,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.43,
                          color: isDark
                              ? const Color(0xFFD4D4D4)
                              : const Color(0xFF525252)),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? const Color(0xFF1F2937)
                            : const Color(0xFFF3F4F6),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      StatWidget(
                          emoji: '🙏',
                          count: p.reactionsCount,
                          isDark: isDark),
                      const SizedBox(width: 16),
                      StatWidget(
                          emoji: '💬',
                          count: p.commentsCount,
                          isDark: isDark),
                      if (p.isAnswered)
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text('✓ Respondida',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w500)),
                        ),
                      const Spacer(),
                      ReactionButton(
                        iconPath: 'assets/icons/oracao.svg',
                        label: 'Orar',
                        isActive: false,
                        isDark: isDark,
                        onTap: () => widget.onReact('PRAYING'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
