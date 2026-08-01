import 'package:flutter/material.dart';

/// Linha função + diácono para o card de print.
class DeaconScalePrintRow {
  final String position;
  final String memberName;

  const DeaconScalePrintRow({
    required this.position,
    required this.memberName,
  });
}

/// Dados do card visual da escala de diáconos para tirar print.
class DeaconScalePrintCardData {
  final DateTime date;
  final String? eventTitle;
  final String? timeRange;
  final List<DeaconScalePrintRow> positions;

  const DeaconScalePrintCardData({
    required this.date,
    this.eventTitle,
    this.timeRange,
    required this.positions,
  });

  static const positionOrder = [
    'Porta Principal',
    'Porta Lateral',
    'Ceia',
    'Oferta',
    'Estacionamento',
    'Recepção',
    'Apoio',
    'Outro',
  ];

  static const accentColors = [
    Color(0xFF8EC8E8),
    Color(0xFFDCC9A8),
    Color(0xFF8FCFC4),
    Color(0xFFC9B8E0),
    Color(0xFFE8A898),
    Color(0xFFB8D4A8),
    Color(0xFFE0B8C8),
    Color(0xFFA8B8E0),
  ];

  static const bg = Color(0xFFF7F6F2);
  static const navy = Color(0xFF1A2B48);
  static const labelGray = Color(0xFF7A7F8A);
  static const divider = Color(0xFFE2E0DA);
  static const border = Color(0xFF2A3344);

  factory DeaconScalePrintCardData.fromPositions({
    required DateTime date,
    String? eventTitle,
    String? startTime,
    String? endTime,
    required List<({String position, String name})> positions,
  }) {
    final rows = positions
        .map(
          (p) => DeaconScalePrintRow(
            position: p.position.trim().isEmpty ? 'Função' : p.position.trim(),
            memberName: p.name.trim().isEmpty ? 'Membro' : p.name.trim(),
          ),
        )
        .toList();

    rows.sort((a, b) {
      final ai = positionOrder.indexOf(a.position);
      final bi = positionOrder.indexOf(b.position);
      final ao = ai < 0 ? positionOrder.length : ai;
      final bo = bi < 0 ? positionOrder.length : bi;
      if (ao != bo) return ao.compareTo(bo);
      return a.memberName.compareTo(b.memberName);
    });

    String? timeRange;
    final start = startTime?.trim();
    final end = endTime?.trim();
    if (start != null && start.isNotEmpty && end != null && end.isNotEmpty) {
      timeRange = '$start – $end';
    } else if (start != null && start.isNotEmpty) {
      timeRange = start;
    }

    return DeaconScalePrintCardData(
      date: date,
      eventTitle: eventTitle?.trim().isEmpty == true ? null : eventTitle?.trim(),
      timeRange: timeRange,
      positions: rows,
    );
  }
}

/// Card da escala de diáconos — pensado para screenshot.
class DeaconScalePrintCard extends StatelessWidget {
  final DeaconScalePrintCardData data;
  final double maxWidth;

  const DeaconScalePrintCard({
    super.key,
    required this.data,
    this.maxWidth = 360,
  });

  static const _monthsShort = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  String get _dayLabel => data.date.day.toString().padLeft(2, '0');
  String get _monthLabel => _monthsShort[data.date.month - 1];

  @override
  Widget build(BuildContext context) {
    final rows = data.positions;
    final eventTitle = data.eventTitle;
    final timeRange = data.timeRange;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: DeaconScalePrintCardData.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DeaconScalePrintCardData.border, width: 1.4),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ESCALA DE DIÁCONOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
              color: DeaconScalePrintCardData.labelGray,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                height: 1.05,
                color: DeaconScalePrintCardData.navy,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(text: _dayLabel),
                const TextSpan(
                  text: ' / ',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: DeaconScalePrintCardData.labelGray,
                  ),
                ),
                TextSpan(text: _monthLabel),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(
            height: 1,
            thickness: 1,
            color: DeaconScalePrintCardData.divider,
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14, height: 1.3),
              children: [
                const TextSpan(
                  text: 'Culto',
                  style: TextStyle(
                    color: DeaconScalePrintCardData.labelGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const TextSpan(
                  text: '  ·  ',
                  style: TextStyle(color: DeaconScalePrintCardData.labelGray),
                ),
                TextSpan(
                  text: (eventTitle != null && eventTitle.isNotEmpty)
                      ? eventTitle
                      : '—',
                  style: const TextStyle(
                    color: DeaconScalePrintCardData.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (timeRange != null && timeRange.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              timeRange,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: DeaconScalePrintCardData.labelGray,
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (rows.isEmpty)
            _positionTile(
              position: '—',
              memberName: 'Sem funções',
              accent: DeaconScalePrintCardData.accentColors[0],
              showDivider: false,
            )
          else
            ...List.generate(rows.length, (i) {
              return _positionTile(
                position: rows[i].position,
                memberName: rows[i].memberName,
                accent: DeaconScalePrintCardData.accentColors[
                    i % DeaconScalePrintCardData.accentColors.length],
                showDivider: i < rows.length - 1,
              );
            }),
        ],
      ),
    );
  }

  Widget _positionTile({
    required String position,
    required String memberName,
    required Color accent,
    required bool showDivider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 36,
                margin: const EdgeInsets.only(top: 2, right: 12),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                        color: DeaconScalePrintCardData.labelGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      memberName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: DeaconScalePrintCardData.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: DeaconScalePrintCardData.divider,
          ),
      ],
    );
  }
}
