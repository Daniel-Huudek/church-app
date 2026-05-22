import 'package:flutter/material.dart';
import '../../core/config/theme/app_colors.dart';
import '../../core/config/theme/app_spacing.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.default_,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color textColor) = _getColors();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  (Color, Color) _getColors() {
    switch (variant) {
      case AppBadgeVariant.default_:
        return (AppColors.primary100, AppColors.primary700);
      case AppBadgeVariant.success:
        return (const Color(0xFFD1FAE5), AppColors.success);
      case AppBadgeVariant.warning:
        return (const Color(0xFFFEF3C7), AppColors.warning);
      case AppBadgeVariant.error:
        return (const Color(0xFFFEE2E2), AppColors.error);
      case AppBadgeVariant.info:
        return (const Color(0xFFDBEAFE), AppColors.info);
    }
  }
}

enum AppBadgeVariant { default_, success, warning, error, info }
