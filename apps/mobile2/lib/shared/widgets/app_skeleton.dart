import 'package:flutter/material.dart';
import '../../core/config/theme/app_colors.dart';
import '../../core/config/theme/app_spacing.dart';

class AppSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = AppSpacing.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.lightBorder.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class AppSkeletonCard extends StatelessWidget {
  final int lines;

  const AppSkeletonCard({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSkeleton(height: 20, width: 200),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < lines; i++) ...[
              AppSkeleton(
                height: 14,
                width: i == lines - 1 ? 150 : double.infinity,
              ),
              if (i < lines - 1) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}
