import 'package:flutter/material.dart';

class WorshipTabData {
  final String key;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const WorshipTabData({
    required this.key,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class WorshipTabItem extends StatelessWidget {
  final WorshipTabData tab;
  final bool isFocused;
  final bool isDark;
  final VoidCallback onTap;

  const WorshipTabItem({
    super.key,
    required this.tab,
    required this.isFocused,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isFocused
              ? (isDark ? const Color(0x266B7280) : const Color(0x269CA3AF))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFocused ? tab.activeIcon : tab.icon,
              size: 22,
              color: isFocused ? const Color(0xFF008CFF) : const Color(0xFF9CA3AF),
            ),
            if (isFocused) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tab.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF008CFF),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
