import 'package:church_app_mobile/features/members/domain/birthday_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BirthdayMember parses public summary without full member payload', () {
    final item = BirthdayMember.fromJson({
      'id': 'm1',
      'name': 'Ana Silva',
      'avatar': null,
      'birthdayThisYear': '2026-07-29',
      'turningAge': 30,
      'isToday': true,
    });

    expect(item.member.id, 'm1');
    expect(item.member.name, 'Ana Silva');
    expect(item.member.email, isNull);
    expect(item.member.phone, isNull);
    expect(item.turningAge, 30);
    expect(item.isToday, isTrue);
  });
}
