import 'member_model.dart';

class BirthdayMember {
  final MemberModel member;
  final DateTime birthdayThisYear;
  final int turningAge;
  final bool isToday;

  const BirthdayMember({
    required this.member,
    required this.birthdayThisYear,
    required this.turningAge,
    required this.isToday,
  });

  factory BirthdayMember.fromJson(Map<String, dynamic> json) {
    return BirthdayMember(
      member: MemberModel.fromJson(json),
      birthdayThisYear: DateTime.parse(json['birthdayThisYear'] as String),
      turningAge: (json['turningAge'] as num?)?.toInt() ?? 0,
      isToday: json['isToday'] as bool? ?? false,
    );
  }
}

class BirthdayListResult {
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final int total;
  final List<BirthdayMember> items;

  const BirthdayListResult({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.total,
    required this.items,
  });

  factory BirthdayListResult.empty({String period = 'week'}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return BirthdayListResult(
      period: period,
      startDate: today,
      endDate: today,
      total: 0,
      items: const [],
    );
  }

  factory BirthdayListResult.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => BirthdayMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return BirthdayListResult(
      period: json['period'] as String? ?? 'week',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      total: (json['total'] as num?)?.toInt() ?? items.length,
      items: items,
    );
  }
}
