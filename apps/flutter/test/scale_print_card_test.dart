import 'package:church_app_mobile/features/worship/presentation/widgets/scale_print_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScalePrintCardData.fromAssignments', () {
    test('separates vocals from instruments and orders instruments', () {
      final data = ScalePrintCardData.fromAssignments(
        date: DateTime(2026, 8, 2),
        ministerName: 'Giselle',
        musicians: [
          (instrument: 'Guitarra', name: 'Felipe'),
          (instrument: 'Vocal', name: 'João'),
          (instrument: 'Bateria', name: 'Cadu'),
          (instrument: 'Baixo', name: 'Pedro'),
          (instrument: 'vocais', name: 'Isa'),
          (instrument: 'Violão', name: 'Marcos'),
          (instrument: 'Teclado', name: 'Zezinha'),
        ],
      );

      expect(data.ministerName, 'Giselle');
      expect(data.vocals, ['João', 'Isa']);
      expect(
        data.instruments.map((e) => '${e.instrument}:${e.musician}').toList(),
        [
          'Bateria:Cadu',
          'Baixo:Pedro',
          'Violão:Marcos',
          'Teclado:Zezinha',
          'Guitarra:Felipe',
        ],
      );
    });

    test('treats empty instrument as Louvor (not vocal)', () {
      final data = ScalePrintCardData.fromAssignments(
        date: DateTime(2026, 1, 1),
        musicians: [
          (instrument: null, name: 'Ana'),
          (instrument: '', name: 'Bruno'),
          (instrument: 'Voz', name: 'Carla'),
        ],
      );

      expect(data.vocals, ['Carla']);
      expect(data.instruments.map((e) => e.instrument).toList(), ['Louvor', 'Louvor']);
    });
  });
}
