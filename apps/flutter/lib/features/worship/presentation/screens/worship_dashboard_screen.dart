import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    _WorshipTabData(key: 'scale', label: 'Escala', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month),
    _WorshipTabData(key: 'repertorio', label: 'Repertório', icon: Icons.library_music_outlined, activeIcon: Icons.library_music),
    _WorshipTabData(key: 'mensagem', label: 'Mensagem', icon: Icons.message_outlined, activeIcon: Icons.message),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _ScalePage(isDark: isDark, scaleTab: _scaleTab, onTabChanged: (v) => setState(() => _scaleTab = v)),
          _RepertorioPage(isDark: isDark, repertorioTab: _repertorioTab, onTabChanged: (v) => setState(() => _repertorioTab = v)),
          const Center(child: Text('Mensagem', style: TextStyle(fontSize: 18))),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xEF161622)
                  : const Color(0xEFFFFFFF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                for (int i = 0; i < _tabs.length; i++) ...[
                  Expanded(
                    child: _WorshipTabItem(
                      tab: _tabs[i],
                      isFocused: _currentIndex == i,
                      isDark: isDark,
                      onTap: () => setState(() => _currentIndex = i),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF008CFF),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
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

class _ScalePage extends StatelessWidget {
  final bool isDark;
  final int scaleTab;
  final ValueChanged<int> onTabChanged;

  const _ScalePage({
    required this.isDark,
    required this.scaleTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
            'Minhas Escalas',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF008CFF),
            ),
            ),
          ),
          const SizedBox(height: 20),
          _SegmentedTab(
            isDark: isDark,
            currentTab: scaleTab,
            onTabChanged: onTabChanged,
            labels: const ['Próximas', 'Anteriores'],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Text(
                scaleTab == 0 ? 'Nenhuma escala futura' : 'Nenhuma escala passada',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepertorioPage extends StatelessWidget {
  final bool isDark;
  final int repertorioTab;
  final ValueChanged<int> onTabChanged;

  const _RepertorioPage({
    required this.isDark,
    required this.repertorioTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
            'Repertório',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF008CFF),
            ),
            ),
          ),
          const SizedBox(height: 20),
          _SegmentedTab(
            isDark: isDark,
            currentTab: repertorioTab,
            onTabChanged: onTabChanged,
            labels: const ['Músicas', 'Artistas'],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Text(
                repertorioTab == 0 ? 'Nenhum repertório futuro' : 'Nenhum repertório passado',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTab extends StatelessWidget {
  final bool isDark;
  final int currentTab;
  final ValueChanged<int> onTabChanged;
  final List<String> labels;

  const _SegmentedTab({
    required this.isDark,
    required this.currentTab,
    required this.onTabChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF008CFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(labels.length, (i) => Expanded(
          child: GestureDetector(
            onTap: () => onTabChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: currentTab == i ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: currentTab == i ? const Color(0xFF008CFF) : Colors.white,
                ),
              ),
            ),
          ),
        )),
      ),
    );
  }
}

class _WorshipTabData {
  final String key;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _WorshipTabData({
    required this.key,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _WorshipTabItem extends StatelessWidget {
  final _WorshipTabData tab;
  final bool isFocused;
  final bool isDark;
  final VoidCallback onTap;

  const _WorshipTabItem({
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
              ? (isDark
                  ? const Color(0x266B7280)
                  : const Color(0x269CA3AF))
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
