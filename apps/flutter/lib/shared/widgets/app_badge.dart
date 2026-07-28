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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color bg, Color textColor) = _getColors(isDark);

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

  (Color, Color) _getColors(bool isDark) {
    switch (variant) {
      case AppBadgeVariant.default_:
        return isDark
            ? (AppColors.primary900.withValues(alpha: 0.45), AppColors.primary300)
            : (AppColors.primary100, AppColors.primary700);
      case AppBadgeVariant.success:
        return isDark
            ? (AppColors.success.withValues(alpha: 0.2), const Color(0xFF6EE7B7))
            : (AppColors.successLight, AppColors.success);
      case AppBadgeVariant.warning:
        return isDark
            ? (AppColors.warning.withValues(alpha: 0.2), const Color(0xFFFCD34D))
            : (AppColors.warningLight, AppColors.warning);
      case AppBadgeVariant.error:
        return isDark
            ? (AppColors.error.withValues(alpha: 0.2), const Color(0xFFFCA5A5))
            : (AppColors.errorLight, AppColors.error);
      case AppBadgeVariant.info:
        return isDark
            ? (AppColors.info.withValues(alpha: 0.2), AppColors.primary300)
            : (const Color(0xFFDBEAFE), AppColors.info);
    }
  }
}

enum AppBadgeVariant { default_, success, warning, error, info }
