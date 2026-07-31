import 'package:flutter/material.dart';

/// Linha instrumento + músico para o card de print da escala.
class ScalePrintInstrumentRow {
  final String instrument;
  final String musician;

  const ScalePrintInstrumentRow({
    required this.instrument,
    required this.musician,
  });
}

/// Dados do card visual moderno para tirar print e compartilhar.
class ScalePrintCardData {
  final DateTime date;
  final String? ministerName;
  final List<ScalePrintInstrumentRow> instruments;
  final List<String> vocals;

  const ScalePrintCardData({
    required this.date,
    this.ministerName,
    required this.instruments,
    required this.vocals,
  });

  static const instrumentOrder = [
    'Bateria',
    'Baixo',
    'Violão',
    'Teclado',
    'Piano',
    'Guitarra',
    'Violino',
    'Saxofone',
    'Percussão',
    'Outro',
  ];

  /// Faixas de accent pastel (mockup B).
  static const accentColors = [
    Color(0xFF8EC8E8), // azul céu
    Color(0xFFDCC9A8), // areia
    Color(0xFF8FCFC4), // menta/teal
    Color(0xFFC9B8E0), // lavanda
    Color(0xFFE8A898), // coral/pêssego
    Color(0xFFB8D4A8), // verde suave
    Color(0xFFE0B8C8), // rosa
    Color(0xFFA8B8E0), // azul lavanda
  ];

  static const bg = Color(0xFFF7F6F2);
  static const navy = Color(0xFF1A2B48);
  static const labelGray = Color(0xFF7A7F8A);
  static const divider = Color(0xFFE2E0DA);
  static const vocalsBg = Color(0xFFE8EEE4);
  static const vocalsText = Color(0xFF2D4236);
  static const border = Color(0xFF2A3344);

  /// Monta o card a partir de músicos brutos (instrumento + nome).
  factory ScalePrintCardData.fromAssignments({
    required DateTime date,
    String? ministerName,
    required List<({String? instrument, String name})> musicians,
  }) {
    final vocals = <String>[];
    final instrumentRows = <ScalePrintInstrumentRow>[];

    for (final m in musicians) {
      final raw = (m.instrument ?? '').trim();
      final lower = raw.toLowerCase();
      final isVocal =
          lower == 'vocal' || lower == 'vocais' || lower == 'voz';
      if (isVocal) {
        vocals.add(m.name);
      } else {
        instrumentRows.add(
          ScalePrintInstrumentRow(
            instrument: raw.isEmpty ? 'Louvor' : raw,
            musician: m.name,
          ),
        );
      }
    }

    instrumentRows.sort((a, b) {
      final ai = instrumentOrder.indexOf(a.instrument);
      final bi = instrumentOrder.indexOf(b.instrument);
      final ao = ai < 0 ? instrumentOrder.length : ai;
      final bo = bi < 0 ? instrumentOrder.length : bi;
      if (ao != bo) return ao.compareTo(bo);
      return a.musician.compareTo(b.musician);
    });

    return ScalePrintCardData(
      date: date,
      ministerName: ministerName,
      instruments: instrumentRows,
      vocals: vocals,
    );
  }
}

/// Card moderno da escala — pensado para screenshot.
class ScalePrintCard extends StatelessWidget {
  final ScalePrintCardData data;
  final double maxWidth;

  const ScalePrintCard({
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
    final rows = data.instruments;
    final vocals = data.vocals;
    final minister = data.ministerName?.trim();

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: ScalePrintCardData.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ScalePrintCardData.border, width: 1.4),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ESCALA DE LOUVOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
              color: ScalePrintCardData.labelGray,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                height: 1.05,
                color: ScalePrintCardData.navy,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(text: _dayLabel),
                const TextSpan(
                  text: ' / ',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: ScalePrintCardData.labelGray,
                  ),
                ),
                TextSpan(text: _monthLabel),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: ScalePrintCardData.divider),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14, height: 1.3),
              children: [
                const TextSpan(
                  text: 'Ministro',
                  style: TextStyle(
                    color: ScalePrintCardData.labelGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const TextSpan(
                  text: '  ·  ',
                  style: TextStyle(color: ScalePrintCardData.labelGray),
                ),
                TextSpan(
                  text: (minister != null && minister.isNotEmpty) ? minister : '—',
                  style: const TextStyle(
                    color: ScalePrintCardData.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (rows.isEmpty)
                        _instrumentTile(
                          instrument: '—',
                          musician: 'Sem músicos',
                          accent: ScalePrintCardData.accentColors[0],
                          showDivider: false,
                        )
                      else
                        ...List.generate(rows.length, (i) {
                          return _instrumentTile(
                            instrument: rows[i].instrument,
                            musician: rows[i].musician,
                            accent: ScalePrintCardData.accentColors[
                                i % ScalePrintCardData.accentColors.length],
                            showDivider: i < rows.length - 1,
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: _vocalsPanel(vocals),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instrumentTile({
    required String instrument,
    required String musician,
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
                      instrument.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                        color: ScalePrintCardData.labelGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      musician,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: ScalePrintCardData.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: ScalePrintCardData.divider),
      ],
    );
  }

  Widget _vocalsPanel(List<String> vocals) {
    return Container(
      decoration: BoxDecoration(
        color: ScalePrintCardData.vocalsBg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Vocais',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ScalePrintCardData.vocalsText,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: ScalePrintCardData.vocalsText.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 14),
          if (vocals.isEmpty)
            const Text(
              '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ScalePrintCardData.vocalsText,
              ),
            )
          else
            ...List.generate(vocals.length, (i) {
              return Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                child: Text(
                  vocals[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: ScalePrintCardData.vocalsText,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
