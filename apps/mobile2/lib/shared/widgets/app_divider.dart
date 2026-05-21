import 'package:flutter/material.dart';
import '../../core/config/theme/app_spacing.dart';
import '../../core/config/theme/app_typography.dart';

class AppDivider extends StatelessWidget {
  final String? label;

  const AppDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return const Divider();
    }

    return Row(
      children: [
        const Expanded(child: Divider()),
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              label!,
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ],
    );
  }
}
