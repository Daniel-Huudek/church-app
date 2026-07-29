import 'package:church_app_mobile/features/members/presentation/utils/member_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('whatsAppPhoneDigits', () {
    test('adds Brazil country code for local numbers', () {
      expect(whatsAppPhoneDigits('(14) 99999-8888'), '5514999998888');
      expect(whatsAppPhoneDigits('14999998888'), '5514999998888');
      expect(whatsAppPhoneDigits('1433334444'), '551433334444');
    });

    test('keeps existing 55 country code', () {
      expect(whatsAppPhoneDigits('+55 14 99999-8888'), '5514999998888');
      expect(whatsAppPhoneDigits('5514999998888'), '5514999998888');
    });
  });

  group('whatsAppUri', () {
    test('builds wa.me link', () {
      expect(
        whatsAppUri('(14) 99999-8888')?.toString(),
        'https://wa.me/5514999998888',
      );
      expect(whatsAppUri(''), isNull);
    });
  });

  group('googleMapsUri', () {
    test('builds maps search url from address parts', () {
      final uri = googleMapsUri(
        street: 'Rua das Flores',
        number: '100',
        neighborhood: 'Centro',
        city: 'Avaré',
        state: 'SP',
        zipCode: '18700-000',
      );
      expect(uri, isNotNull);
      expect(uri!.host, 'www.google.com');
      expect(uri.path, '/maps/search/');
      expect(uri.queryParameters['api'], '1');
      expect(
        uri.queryParameters['query'],
        'Rua das Flores, 100, Centro, Avaré - SP, 18700-000',
      );
    });

    test('returns null when address is empty', () {
      expect(googleMapsUri(), isNull);
    });
  });
}
