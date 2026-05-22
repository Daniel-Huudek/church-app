import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../providers/prayer_provider.dart';
import '../../data/prayer_api.dart';
import '../../domain/prayer_model.dart';

class PrayerFeedScreen extends ConsumerStatefulWidget {
  const PrayerFeedScreen({super.key});

  @override
  ConsumerState<PrayerFeedScreen> createState() => _PrayerFeedScreenState();
}

class _PrayerFeedScreenState extends ConsumerState<PrayerFeedScreen> {
  int _activeTab = 0;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future(() => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _load() {
    if (_activeTab == 0) {
      ref.read(prayerFeedProvider.notifier).loadFeed();
    } else {
      ref.read(prayerFeedProvider.notifier).loadMine();
    }
  }

  Future<void> _onRefresh() async {
    _load();
  }

  List<PrayerModel> _filtered(List<PrayerModel> prayers) {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return prayers;
    return prayers.where((p) {
      return p.content.toLowerCase().contains(q) ||
          p.authorName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insets = MediaQuery.of(context).padding;
    final state = ref.watch(prayerFeedProvider);
    final list = _filtered(state.prayers);
    final feedCount = state.prayers.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, insets.top + 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orações',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFF9FAFB)
                              : const Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Text(_countText(state.prayers.length),
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280))),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🔍', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar pedidos...',
                        hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF),
                            fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                          color: isDark
                              ? const Color(0xFFF9FAFB)
                              : const Color(0xFF111827),
                          fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'Pedidos ($feedCount)',
                      isActive: _activeTab == 0,
                      isDark: isDark,
                      onTap: () {
                        setState(() => _activeTab = 0);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TabButton(
                      label: 'Meus (${_mineCount(state.prayers)})',
                      isActive: _activeTab == 1,
                      isDark: isDark,
                      onTap: () {
                        setState(() => _activeTab = 1);
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                        color: Color(0xFFEF4444), fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                      ? _buildEmpty(isDark, _activeTab == 1)
                      : RefreshIndicator(
                          onRefresh: _onRefresh,
                          color: const Color(0xFF008CFF),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: list.length,
                            itemBuilder: (context, index) => _PrayerCard(
                              prayer: list[index],
                              isDark: isDark,
                              index: index,
                              onTap: () => context.push('/prayers/${list[index].id}'),
                              onReact: (type) {
                                ref.read(prayerApiProvider).toggleReaction(list[index].id, type);
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/prayers/create'),
        backgroundColor: const Color(0xFF008CFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Image.asset('assets/images/add.png',
            width: 24, height: 24, color: Colors.white),
      ),
    );
  }

  int _mineCount(List<PrayerModel> prayers) {
    return prayers.length;
  }

  String _countText(int c) {
    if (c == 0) return 'Nenhum pedido ainda';
    if (c == 1) return '1 pedido registrado';
    return '$c pedidos registrados';
  }

  Widget _buildEmpty(bool isDark, bool isMine) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF008CFF),
      child: ListView(
        children: [
          const SizedBox(height: 60),
          Center(
            child: Column(
              children: [
                const Text('🙏', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  isMine
                      ? 'Você ainda não fez pedidos'
                      : 'Nenhum pedido de oração',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF9FAFB)
                          : const Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compartilhe seus pedidos com a igreja',
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF008CFF)
              : (isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}

class _PrayerCard extends StatefulWidget {
  final PrayerModel prayer;
  final bool isDark;
  final int index;
  final VoidCallback onTap;
  final void Function(String type) onReact;

  const _PrayerCard({
    required this.prayer,
    required this.isDark,
    required this.index,
    required this.onTap,
    required this.onReact,
  });

  @override
  State<_PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<_PrayerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _slideAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _initials {
    final name = widget.prayer.authorName;
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prayer;
    final isDark = widget.isDark;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Opacity(
        opacity: _opacityAnim.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: p.isUrgent
                  ? Border.all(color: const Color(0xFFEF4444), width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.isUrgent)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('URGENTE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1)),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: p.isAnonymous
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF008CFF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          p.isAnonymous ? '??' : _initials,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.isAnonymous ? 'Anônimo' : p.authorName,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFF9FAFB)
                                    : const Color(0xFF111827)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(p.createdAt),
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ),
                    if (p.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF008CFF).withValues(alpha: 0.13)
                              : const Color(0xFF008CFF).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(p.categoryName!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF008CFF),
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                if (p.title.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(p.title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFF9FAFB)
                              : const Color(0xFF111827))),
                ],
                if (p.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(p.content,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.43,
                          color: isDark
                              ? const Color(0xFFD4D4D4)
                              : const Color(0xFF525252)),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? const Color(0xFF1F2937)
                            : const Color(0xFFF3F4F6),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _Stat(
                          emoji: '🙏',
                          count: p.reactionsCount,
                          isDark: isDark),
                      const SizedBox(width: 16),
                      _Stat(
                          emoji: '💬',
                          count: p.commentsCount,
                          isDark: isDark),
                      if (p.isAnswered)
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text('✓ Respondida',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w500)),
                        ),
                      const Spacer(),
                      _ReactionBtn(
                        iconPath: 'assets/icons/oracao.svg',
                        label: 'Orar',
                        isActive: false,
                        isDark: isDark,
                        onTap: () => widget.onReact('PRAYING'),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}

class _Stat extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isDark;

  const _Stat({required this.emoji, required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text('$count',
            style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))),
      ],
    );
  }
}

class _ReactionBtn extends StatelessWidget {
  final String? iconPath;
  final String emoji;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _ReactionBtn({
    this.iconPath,
    this.emoji = '',
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? (isDark
            ? const Color(0xFF008CFF).withValues(alpha: 0.25)
            : const Color(0xFF008CFF).withValues(alpha: 0.12))
        : (isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6));
    final fg = isActive
        ? const Color(0xFF008CFF)
        : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconPath != null
                ? SvgPicture.asset(iconPath!,
                    width: 13, height: 13,
                    colorFilter: ColorFilter.mode(fg, BlendMode.srcIn))
                : Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(label,
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
          ],
        ),
      ),
    );
  }
}
