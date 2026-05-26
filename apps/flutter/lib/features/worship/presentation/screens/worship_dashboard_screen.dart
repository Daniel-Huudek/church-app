import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../widgets/worship_tab_item.dart';
import '../widgets/scale_page.dart';
import '../widgets/repertorio_page.dart';
import '../widgets/mensagem_page.dart';

class WorshipDashboardScreen extends ConsumerStatefulWidget {
  const WorshipDashboardScreen({super.key});

  @override
  ConsumerState<WorshipDashboardScreen> createState() => _WorshipDashboardScreenState();
}

class _WorshipDashboardScreenState extends ConsumerState<WorshipDashboardScreen> {
  int _currentIndex = 0;
  int _scaleTab = 0;
  int _repertorioTab = 0;

  final _tabs = [
    WorshipTabData(key: 'scale', label: 'Escala', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month),
    WorshipTabData(key: 'repertorio', label: 'Repertório', icon: Icons.library_music_outlined, activeIcon: Icons.library_music),
    WorshipTabData(key: 'mensagem', label: 'Mensagem', icon: Icons.message_outlined, activeIcon: Icons.message),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final canCreate = user != null && user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER', 'LIDER_LOUVOR']);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ScalePage(isDark: isDark, scaleTab: _scaleTab, onTabChanged: (v) => setState(() => _scaleTab = v), canCreate: canCreate),
          RepertorioPage(isDark: isDark, repertorioTab: _repertorioTab, onTabChanged: (v) => setState(() => _repertorioTab = v), canCreate: canCreate),
          MensagemPage(isDark: isDark, canCreate: canCreate),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xEF161622) : const Color(0xEFFFFFFF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 20, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                for (int i = 0; i < _tabs.length; i++) ...[
                  Expanded(
                    child: WorshipTabItem(
                      tab: _tabs[i],
                      isFocused: _currentIndex == i,
                      isDark: isDark,
                      onTap: () => setState(() => _currentIndex = i),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.home_rounded, color: Color(0xFF008CFF), size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
