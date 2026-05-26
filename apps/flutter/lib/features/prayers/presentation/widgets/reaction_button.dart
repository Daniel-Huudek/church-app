import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReactionButton extends StatelessWidget {
  final String? iconPath;
  final String emoji;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const ReactionButton({
    this.iconPath,
    this.emoji = '',
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? (isDark
            ? const Color(0xFF008CFF).withValues(alpha: 0.25)
            : const Color(0xFF008CFF).withValues(alpha: 0.12))
        : (isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6));
    final fg = isActive
        ? const Color(0xFF008CFF)
        : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconPath != null
                ? SvgPicture.asset(iconPath!,
                    width: 13, height: 13,
                    colorFilter: ColorFilter.mode(fg, BlendMode.srcIn))
                : Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(label,
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
          ],
        ),
      ),
    );
  }
}
