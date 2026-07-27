import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeState = ref.watch(themeProvider);
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

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
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('←', style: TextStyle(fontSize: 24)),
          ),
        ),
        title: Text('Configurações',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t1)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          Text('APARÊNCIA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t2, letterSpacing: 1)),
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
              trailing: const Icon(Icons.chevron_right),
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
          Text('SOBRE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t2, letterSpacing: 1)),
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
