import 'package:church_app_mobile/features/members/data/cep_lookup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeCep / formatCep', () {
    test('remove non-digits and caps at 8', () {
      expect(normalizeCep('13.010-100'), '13010100');
      expect(normalizeCep('13010100123'), '13010100');
      expect(normalizeCep('abc'), '');
    });

    test('formats complete CEP with hyphen', () {
      expect(formatCep('13010100'), '13010-100');
      expect(formatCep('13010'), '13010');
      expect(formatCep('13.010-100'), '13010-100');
    });
  });

  group('CepAddress.fromViaCep', () {
    test('maps ViaCEP fields to member address fields', () {
      final address = CepAddress.fromViaCep({
        'cep': '01310-100',
        'logradouro': 'Avenida Paulista',
        'bairro': 'Bela Vista',
        'localidade': 'São Paulo',
        'uf': 'sp',
      });

      expect(address.zipCode, '01310-100');
      expect(address.street, 'Avenida Paulista');
      expect(address.neighborhood, 'Bela Vista');
      expect(address.city, 'São Paulo');
      expect(address.state, 'SP');
    });
  });
}
