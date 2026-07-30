import 'package:church_app_mobile/shared/utils/person_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('preferredPersonName', () {
    test('prefers nickname when present', () {
      expect(
        preferredPersonName(name: 'João Silva Santos', nickname: 'Jão'),
        'Jão',
      );
    });

    test('falls back to full name without nickname', () {
      expect(
        preferredPersonName(name: 'João Silva Santos', nickname: null),
        'João Silva Santos',
      );
    });
  });

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

  group('scaleCopyDisplayName', () {
    test('prefers nickname when present', () {
      expect(
        scaleCopyDisplayName(name: 'João Silva Santos', nickname: 'Jão'),
        'Jão',
      );
    });

    test('falls back to abbreviated name without nickname', () {
      expect(
        scaleCopyDisplayName(name: 'João Silva Santos', nickname: null),
        'João S. S.',
      );
      expect(
        scaleCopyDisplayName(name: 'João Silva Santos', nickname: '  '),
        'João S. S.',
      );
    });
  });
}
