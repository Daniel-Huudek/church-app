import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../shared/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeState = ref.watch(themeProvider);
    final bg = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final t1 = isDark ? AppColors.darkText : AppColors.lightText;
    final t2 = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    String themeLabel;
    switch (themeState.themeMode) {
      case ThemeMode.dark:
        themeLabel = 'Escuro';
        break;
      case ThemeMode.light:
        themeLabel = 'Claro';
        break;
      default:
        themeLabel = 'Sistema';
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_rounded, color: t1),
        ),
        title: Text(
          'Configurações',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          Text(
            'APARÊNCIA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: t2,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: ListTile(
              title: Text('Tema', style: TextStyle(color: t1)),
              subtitle: Text(themeLabel, style: TextStyle(color: t2)),
              trailing: Icon(Icons.chevron_right_rounded, color: t2),
              onTap: () async {
                final next = themeState.themeMode == ThemeMode.light
                    ? ThemeMode.dark
                    : themeState.themeMode == ThemeMode.dark
                        ? ThemeMode.system
                        : ThemeMode.light;
                await ref.read(themeProvider.notifier).setThemeMode(next);
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'SOBRE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: t2,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: ListTile(
              title: Text('Versão', style: TextStyle(color: t1)),
              trailing: Text('1.0.0', style: TextStyle(color: t2)),
            ),
          ),
        ],
      ),
    );
  }
}
