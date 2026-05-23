import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/worship_api.dart';
import '../../domain/worship_models.dart';
import '../providers/worship_provider.dart';
import '../../../events/data/event_api.dart';
import '../../../events/domain/event_model.dart';

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
    final user = ref.watch(authProvider).user;
    final canCreate = user != null && user.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER', 'LIDER_LOUVOR']);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _ScalePage(isDark: isDark, scaleTab: _scaleTab, onTabChanged: (v) => setState(() => _scaleTab = v), canCreate: canCreate),
          _RepertorioPage(isDark: isDark, repertorioTab: _repertorioTab, onTabChanged: (v) => setState(() => _repertorioTab = v), canCreate: canCreate),
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
                  onTap: () => context.go('/'),
                  child: Container(
                    width: 36,
                    height: 36,
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

class _ScalePage extends ConsumerStatefulWidget {
  final bool isDark;
  final int scaleTab;
  final ValueChanged<int> onTabChanged;
  final bool canCreate;

  const _ScalePage({
    required this.isDark,
    required this.scaleTab,
    required this.onTabChanged,
    required this.canCreate,
  });

  @override
  ConsumerState<_ScalePage> createState() => _ScalePageState();
}

class _ScaleCardData {
  final WorshipEvent worshipEvent;
  final EventModel? event;
  _ScaleCardData({required this.worshipEvent, this.event});
}

class _ScalePageState extends ConsumerState<_ScalePage> {
  List<_ScaleCardData> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final worshipApi = WorshipApi(ref.read(apiClientProvider));
      final eventApi = EventApi(ref.read(apiClientProvider));
      final res = await worshipApi.listWorshipEvents(limit: 50);
      final data = (res['data'] as List?) ?? [];
      final events = data.map((e) => WorshipEvent.fromJson(e as Map<String, dynamic>)).toList();
      final items = <_ScaleCardData>[];
      for (final we in events) {
        EventModel? eventModel;
        try {
          eventModel = await eventApi.getById(we.eventId);
        } catch (_) {}
        items.add(_ScaleCardData(worshipEvent: we, event: eventModel));
      }
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final scaleTab = widget.scaleTab;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentUser = ref.read(authProvider).user;
    final currentUserId = currentUser?.id;
    final showAll = currentUser?.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER', 'LIDER_LOUVOR']) ?? false;

    final filtered = _items.where((item) {
      if (!showAll) {
        final musicians = item.worshipEvent.musicians ?? [];
        if (currentUserId != null && musicians.isNotEmpty && !musicians.any((m) => m.memberId == currentUserId)) return false;
      }
      final date = item.event?.date ?? item.worshipEvent.createdAt;
      final eventDate = DateTime(date.year, date.month, date.day);
      return scaleTab == 0 ? eventDate.isAfter(today.subtract(const Duration(days: 1))) : eventDate.isBefore(today);
    }).toList()
      ..sort((a, b) {
        final aDate = a.event?.date ?? a.worshipEvent.createdAt;
        final bDate = b.event?.date ?? b.worshipEvent.createdAt;
        return scaleTab == 0 ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      });

    return Stack(
      children: [
        Padding(
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
                onTabChanged: widget.onTabChanged,
                labels: const ['Próximas', 'Anteriores'],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              scaleTab == 0 ? 'Nenhuma escala futura' : 'Nenhuma escala passada',
                              style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (_, i) {
                              final item = filtered[i];
                              final we = item.worshipEvent;
                              final ev = item.event;
                              final songs = we.songs ?? [];
                              final musicians = we.musicians ?? [];
                              final startTime = ev?.startTime ?? '--:--';
                              final confirmedCount = musicians.where((m) => m.isConfirmed).length;
                              final substitutedCount = musicians.where((m) => m.isSubstituted).length;
                              final title = ev?.title ?? 'Evento';
                              final date = ev?.date ?? we.createdAt;
                              final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
                              final day = date.day.toString().padLeft(2, '0');
                              final month = months[date.month - 1];

                              return GestureDetector(
                                onTap: () => context.push('/worship/scale/${we.id}'),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF008CFF),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF008CFF), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF008CFF).withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 48, height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(title,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.schedule_rounded, size: 14, color: Colors.white70),
                                                    const SizedBox(width: 4),
                                                    Text(startTime,
                                                      style: const TextStyle(fontSize: 13, color: Colors.white70)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(day,
                                                  style: const TextStyle(color: Color(0xFF008CFF), fontSize: 18, fontWeight: FontWeight.w800)),
                                                Text(month,
                                                  style: const TextStyle(color: Color(0xFF008CFF), fontSize: 10, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                                      ),
                                      Row(
                                        children: [
                                          _statBadge(Icons.music_note_rounded, '${songs.length} músicas', isDark),
                                          const SizedBox(width: 10),
                                          _statBadge(
                                            Icons.people_rounded,
                                            '$confirmedCount/${musicians.length} pessoas',
                                            isDark,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        if (widget.canCreate)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 20),
              child: GestureDetector(
                onTap: () async { await context.push('/worship/scale/create'); _load(); },
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF008CFF),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _statBadge(IconData icon, String label, bool isDark, {Color? color}) {
    final c = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }
}

class _RepertorioPage extends ConsumerStatefulWidget {
  final bool isDark;
  final int repertorioTab;
  final ValueChanged<int> onTabChanged;
  final bool canCreate;

  const _RepertorioPage({
    required this.isDark,
    required this.repertorioTab,
    required this.onTabChanged,
    required this.canCreate,
  });

  @override
  ConsumerState<_RepertorioPage> createState() => _RepertorioPageState();
}

class _RepertorioPageState extends ConsumerState<_RepertorioPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsProvider);
    final isDark = widget.isDark;
    final repertorioTab = widget.repertorioTab;

    return Stack(
      children: [
        Padding(
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
                onTabChanged: widget.onTabChanged,
                labels: const ['Músicas', 'Artistas'],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: repertorioTab == 0 ? _buildMusicas(isDark, songsAsync) : _buildArtistas(isDark),
              ),
            ],
          ),
        ),
        if (widget.canCreate)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 20),
              child: GestureDetector(
                onTap: () => context.push('/worship/repertorio/create'),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF008CFF),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMusicas(bool isDark, AsyncValue<List<Song>> songsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: 'Buscar músicas...',
              hintStyle: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
              prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: songsAsync.when(
            data: (songs) {
              final query = _searchCtrl.text.toLowerCase();
              final filtered = query.isEmpty
                  ? songs
                  : songs.where((s) =>
                      s.title.toLowerCase().contains(query) ||
                      (s.artist?.toLowerCase().contains(query) ?? false)).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    query.isEmpty ? 'Nenhuma música cadastrada' : 'Nenhuma música encontrada',
                    style: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                  ),
                );
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final song = filtered[i];
                  return GestureDetector(
                    onTap: () => context.push('/worship/songs/${song.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161622) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.music_note_rounded, color: Color(0xFF008CFF), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(song.title,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF111827))),
                                if (song.artist != null) ...[
                                  const SizedBox(height: 3),
                                  Text(song.artist!,
                                    style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
                                ],
                              ],
                            ),
                          ),
                          if (song.key != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(song.key!,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF008CFF))),
                            ),
                          if (song.youtubeUrl != null) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => launchUrl(Uri.parse(song.youtubeUrl!)),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFEF4444), size: 18),
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, color: isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB), size: 22),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e', style: const TextStyle(color: Color(0xFFEF4444)))),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistas(bool isDark) {
    return Center(
      child: Text(
        'Em breve',
        style: TextStyle(
          fontSize: 14,
          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        ),
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
