import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/event_card.dart';
import '../../domain/event_model.dart';
import '../providers/event_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late int _currentYear;
  late int _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month + 1;
  }

  String _getMonthName(int year, int month) {
    final months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return '${months[month - 1]} de $year';
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth += delta;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      } else if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
    });
  }

  List<EventModel> _filteredEvents(List<EventModel> events) {
    return events.where((e) =>
      e.date.year == _currentYear && e.date.month == _currentMonth
    ).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<_EventSection> _groupByDate(List<EventModel> events) {
    final grouped = <String, List<EventModel>>{};
    for (final event in events) {
      final key = event.date.toIso8601String().substring(0, 10);
      grouped.putIfAbsent(key, () => []).add(event);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    return sortedKeys.map((date) {
      final d = DateTime.tryParse(date);
      final title = d != null
          ? '${_weekdayName(d.weekday)}, ${d.day} de ${_monthName(d.month)}'
          : date;
      return _EventSection(title: title, events: grouped[date]!);
    }).toList();
  }

  String _weekdayName(int wd) {
    const names = [
      'segunda-feira', 'terça-feira', 'quarta-feira',
      'quinta-feira', 'sexta-feira', 'sábado', 'domingo'
    ];
    return names[wd - 1];
  }

  String _monthName(int m) {
    const names = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return names[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(eventListProvider);
    final filtered = _filteredEvents(state.events);
    final sections = _groupByDate(filtered);

    return Container(
      color: isDark ? const Color(0xFF0A0A0F) : Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Text(
                    'Agenda',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _changeMonth(-1),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('‹', style: TextStyle(fontSize: 24)),
                        ),
                      ),
                      Text(
                        _getMonthName(_currentYear, _currentMonth),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _changeMonth(1),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('›', style: TextStyle(fontSize: 24)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : state.error != null
                          ? Center(child: Text('Erro: ${state.error}'))
                          : filtered.isEmpty
                              ? _buildEmpty(isDark)
                              : RefreshIndicator(
                                  onRefresh: () => ref.read(eventListProvider.notifier).load(),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                                    itemCount: sections.length,
                                    itemBuilder: (context, sectionIndex) {
                                      final section = sections[sectionIndex];
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Text(
                                              section.title.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? const Color(0xFF9CA3AF)
                                                    : const Color(0xFF6B7280),
                                              ),
                                            ),
                                          ),
                                          ...section.events.map((event) =>
                                            EventCard(
                                              event: event.toEventCardMap(),
                                              onPress: () => context.go('/calendar/${event.id}'),
                                            )),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                onPressed: () => context.push('/calendar/create'),
                backgroundColor: const Color(0xFF008CFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/images/add.png',
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return RefreshIndicator(
      onRefresh: () => ref.read(eventListProvider.notifier).load(),
      child: ListView(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                const Text('📅', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'Nenhum evento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Não há eventos para este período',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventSection {
  final String title;
  final List<EventModel> events;

  const _EventSection({required this.title, required this.events});
}
