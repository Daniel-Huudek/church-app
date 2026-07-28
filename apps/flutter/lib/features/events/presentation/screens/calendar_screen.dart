import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/offline/offline_guard.dart';
import '../../domain/event_model.dart';
import '../providers/event_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late int _viewYear;
  late int _viewMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _viewYear = now.year;
    _viewMonth = now.month;
  }

  void _prevMonth() {
    setState(() {
      if (_viewMonth == 1) { _viewMonth = 12; _viewYear--; }
      else { _viewMonth--; }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_viewMonth == 12) { _viewMonth = 1; _viewYear++; }
      else { _viewMonth++; }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final accent = AppColors.primary;
    final state = ref.watch(eventListProvider);

    final firstDay = DateTime(_viewYear, _viewMonth, 1);
    final lastDay = DateTime(_viewYear, _viewMonth + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7; // 0=domingo

    final monthEvents = state.data.where((e) =>
      e.date.year == _viewYear && e.date.month == _viewMonth
    ).toList()..sort((a, b) => a.date.compareTo(b.date));

    final selectedEvents = monthEvents.where((e) =>
      e.date.year == _selectedDate.year &&
      e.date.month == _selectedDate.month &&
      e.date.day == _selectedDate.day
    ).toList();

    final eventDates = monthEvents.map((e) => e.date.day).toSet();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Agenda',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${monthEvents.length} eventos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Month navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _prevMonth,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.chevron_left_rounded, color: accent, size: 28),
                      ),
                    ),
                  ),
                  Text(
                    _monthName(_viewMonth).toUpperCase(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Material(color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _nextMonth,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.chevron_right_rounded, color: accent, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Weekday headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'].map((d) =>
                  Expanded(
                    child: Center(
                      child: Text(d, style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      )),
                    ),
                  ),
                ).toList(),
              ),
            ),
            const SizedBox(height: 4),

            // Calendar grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AspectRatio(
                aspectRatio: 7 / 5.5,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: startWeekday + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < startWeekday) return const SizedBox();
                    final day = index - startWeekday + 1;
                    final isToday = day == DateTime.now().day &&
                        _viewMonth == DateTime.now().month &&
                        _viewYear == DateTime.now().year;
                    final isSelected = day == _selectedDate.day &&
                        _viewMonth == _selectedDate.month &&
                        _viewYear == _selectedDate.year;
                    final hasEvent = eventDates.contains(day);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() {
                          _selectedDate = DateTime(_viewYear, _viewMonth, day);
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent
                                : isToday
                                    ? accent.withValues(alpha: 0.1)
                                    : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                          ? accent
                                          : (isDark ? Colors.white70 : Colors.black54),
                                ),
                              ),
                              if (hasEvent)
                                Container(
                                  width: 4, height: 4,
                                  margin: const EdgeInsets.only(top: 3),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Divider with date info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_weekdayName(_selectedDate.weekday)}, ${_selectedDate.day} de ${_monthName(_selectedDate.month)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (selectedEvents.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${selectedEvents.length}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 16, indent: 20, endIndent: 20),

            // Event list
            Expanded(
              child: state.loading && state.data.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && state.data.isEmpty
                      ? Center(child: Text('Erro: ${state.error}', style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)))
                      : selectedEvents.isEmpty
                          ? _emptyDay(isDark, accent)
                          : RefreshIndicator(
                              onRefresh: () => ref.read(eventListProvider.notifier).load(),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                                itemCount: selectedEvents.length,
                                itemBuilder: (_, i) => _EventTile(
                                  event: selectedEvents[i],
                                  onTap: () => context.go('/calendar/${selectedEvents[i].id}'),
                                  isDark: isDark,
                                  accent: accent,
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: Opacity(
        opacity: watchIsOnline(ref) ? 1 : 0.45,
        child: FloatingActionButton(
          onPressed: guardOnlineAction(context, ref, () => context.push('/calendar/create')),
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _emptyDay(bool isDark, Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 40,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary),
          const SizedBox(height: 12),
          Text(
            'Nenhum evento neste dia',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
  ][m - 1];

  String _weekdayName(int wd) => [
    'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'
  ][wd - 1];
}

class _EventTile extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final bool isDark;
  final Color accent;

  const _EventTile({
    required this.event, required this.onTap,
    required this.isDark, required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16161F) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                // Time column
                Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        event.startTime.length >= 5
                            ? event.startTime.substring(0, 5)
                            : event.startTime,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _typeLabel(event.type),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                          if (event.location != null && event.location!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.location_on_outlined, size: 12,
                              color: isDark ? Colors.white30 : Colors.black26),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                event.location!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 18,
                  color: isDark ? Colors.white24 : Colors.black12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    const labels = {
      'WORSHIP': 'Culto',
      'EVENT': 'Evento',
      'REHEARSAL': 'Ensaio',
    };
    return labels[type] ?? 'Evento';
  }
}
