import 'package:flutter/material.dart';

class MenuItemData {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? trailing;

  const MenuItemData({
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
  });
}

class MenuSection extends StatelessWidget {
  final String title;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final List<MenuItemData> items;
  final void Function(int index)? onItemTap;

  const MenuSection({
    required this.title,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onItemTap != null ? () => onItemTap!(index) : null,
                  borderRadius: BorderRadius.vertical(
                    top: index == 0 ? const Radius.circular(16) : Radius.zero,
                    bottom: index == items.length - 1
                        ? const Radius.circular(16)
                        : Radius.zero,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: index < items.length - 1
                          ? Border(bottom: BorderSide(color: borderColor, width: 1))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, color: item.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 15,
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.trailing != null) ...[
                          item.trailing!,
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
