import 'package:church_app_mobile/shared/utils/person_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('abbreviatePersonName', () {
    test('keeps single name', () {
      expect(abbreviatePersonName('Ana'), 'Ana');
      expect(abbreviatePersonName('  Ana  '), 'Ana');
    });

    test('abbreviates surnames to initials', () {
      expect(abbreviatePersonName('João Silva Santos'), 'João S. S.');
      expect(abbreviatePersonName('Maria Clara Souza'), 'Maria C. S.');
    });

    test('skips Portuguese name particles', () {
      expect(abbreviatePersonName('João da Silva'), 'João S.');
      expect(abbreviatePersonName('Ana de Souza Costa'), 'Ana S. C.');
      expect(abbreviatePersonName('Pedro dos Santos'), 'Pedro S.');
    });

    test('handles empty and whitespace', () {
      expect(abbreviatePersonName(''), '');
      expect(abbreviatePersonName('   '), '');
    });
  });
}
