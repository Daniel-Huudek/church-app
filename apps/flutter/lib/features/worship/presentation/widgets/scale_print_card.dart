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

/// Dados do card visual (estilo planilha) para tirar print e compartilhar.
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

  static const rowColors = [
    Color(0xFFB8D4F0), // azul claro
    Color(0xFFE8D5B0), // bege
    Color(0xFFA8DEE8), // ciano
    Color(0xFFE0C8E8), // lavanda
    Color(0xFFF5CBA7), // pêssego
    Color(0xFFD4E8C8), // verde suave
    Color(0xFFF0D0D8), // rosa
    Color(0xFFD0D8F0), // azul lavanda
  ];

  static const vocalsColor = Color(0xFFC5E8B8);
  static const headerYellow = Color(0xFFFFEB3B);
  static const borderColor = Color(0xFF111111);

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

/// Card estilo planilha colorida — pensado para screenshot / compartilhar.
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

  String get _dateLabel {
    final d = data.date.day.toString().padLeft(2, '0');
    final m = _monthsShort[data.date.month - 1];
    return '$d/$m';
  }

  @override
  Widget build(BuildContext context) {
    final rows = data.instruments;
    final vocals = data.vocals;
    // Garante espaço para todos os vocais mesmo se houver mais vocalistas que instrumentos.
    final rowCount = [
      rows.isEmpty ? 1 : rows.length,
      vocals.isEmpty ? 1 : vocals.length,
    ].reduce((a, b) => a > b ? a : b);

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ScalePrintCardData.borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Data (amarelo)
          Container(
            color: ScalePrintCardData.headerYellow,
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Text(
              _dateLabel,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Ministro
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: ScalePrintCardData.borderColor, width: 1.5),
                bottom: BorderSide(color: ScalePrintCardData.borderColor, width: 1.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            alignment: Alignment.center,
            child: Text(
              data.ministerName != null && data.ministerName!.isNotEmpty
                  ? 'Ministro(a): ${data.ministerName}'
                  : 'Ministro(a): —',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          // Cabeçalhos + corpo
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Colunas Instrum + Musico
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _headerPair(),
                      ...List.generate(rowCount, (i) {
                        final hasRow = i < rows.length;
                        return _instrumentRow(
                          instrument: hasRow ? rows[i].instrument : '',
                          musician: hasRow ? rows[i].musician : '',
                          color: ScalePrintCardData.rowColors[
                              i % ScalePrintCardData.rowColors.length],
                          isLast: i == rowCount - 1,
                        );
                      }),
                    ],
                  ),
                ),
                // Coluna Vocais (bloco verde contínuo)
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: ScalePrintCardData.borderColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: ScalePrintCardData.borderColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Vocais',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ColoredBox(
                            color: ScalePrintCardData.vocalsColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: List.generate(rowCount, (i) {
                                final name =
                                    i < vocals.length ? vocals[i] : '';
                                return Expanded(
                                  child: Center(
                                    child: Text(
                                      name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerPair() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: ScalePrintCardData.borderColor, width: 1.5),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Instrum',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: ScalePrintCardData.borderColor,
                    width: 1.5,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Musico',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _instrumentRow({
    required String instrument,
    required String musician,
    required Color color,
    required bool isLast,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(
                  color: ScalePrintCardData.borderColor,
                  width: 1.5,
                ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Text(
                instrument,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: ScalePrintCardData.borderColor,
                    width: 1.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Text(
                musician,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
