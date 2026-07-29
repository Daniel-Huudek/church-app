import 'package:flutter/material.dart';
import '../../domain/event_model.dart';

enum EventLinkMode { existing, createNew }

/// Lets the user either pick an existing calendar event or create a new one
/// when building a ministry scale (worship, deacons, etc.).
class EventSourceSection extends StatelessWidget {
  final bool isDark;
  final EventLinkMode mode;
  final ValueChanged<EventLinkMode> onModeChanged;
  final List<EventModel> events;
  final Set<String> unavailableEventIds;
  final String? selectedEventId;
  final ValueChanged<EventModel> onSelectEvent;
  final String unavailableHint;

  const EventSourceSection({
    super.key,
    required this.isDark,
    required this.mode,
    required this.onModeChanged,
    required this.events,
    required this.selectedEventId,
    required this.onSelectEvent,
    this.unavailableEventIds = const {},
    this.unavailableHint = 'Já possui escala',
  });

  Color get _t1 => isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
  Color get _t2 => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _card => isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF9FAFB);
  Color get _border => isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evento',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _t2),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              _modeChip(
                label: 'Selecionar',
                icon: Icons.event_available_rounded,
                value: EventLinkMode.existing,
              ),
              _modeChip(
                label: 'Criar novo',
                icon: Icons.add_rounded,
                value: EventLinkMode.createNew,
              ),
            ],
          ),
        ),
        if (mode == EventLinkMode.existing) ...[
          const SizedBox(height: 12),
          Text(
            'Use o mesmo evento do culto para Louvor e Diáconos.',
            style: TextStyle(fontSize: 12, color: _t2, height: 1.35),
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Text(
                'Nenhum evento próximo encontrado. Crie um novo ou cadastre em Eventos.',
                style: TextStyle(fontSize: 13, color: _t2),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: events.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: _border),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final unavailable = unavailableEventIds.contains(event.id);
                  final selected = selectedEventId == event.id;
                  final dateLabel =
                      '${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}/${event.date.year}';

                  return ListTile(
                    enabled: !unavailable,
                    selected: selected,
                    selectedTileColor: const Color(0xFF008CFF).withValues(alpha: 0.08),
                    leading: Icon(
                      selected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: unavailable
                          ? _t2
                          : selected
                              ? const Color(0xFF008CFF)
                              : _t2,
                    ),
                    title: Text(
                      event.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: unavailable ? _t2 : _t1,
                      ),
                    ),
                    subtitle: Text(
                      unavailable
                          ? '$dateLabel · ${event.startTime} · $unavailableHint'
                          : '$dateLabel · ${event.startTime}${event.endTime != null ? '–${event.endTime}' : ''}',
                      style: TextStyle(fontSize: 12, color: _t2),
                    ),
                    onTap: unavailable ? null : () => onSelectEvent(event),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _modeChip({
    required String label,
    required IconData icon,
    required EventLinkMode value,
  }) {
    final selected = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF008CFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : _t2),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _t1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
