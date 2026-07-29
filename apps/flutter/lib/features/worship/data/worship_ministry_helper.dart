import '../../members/data/member_api.dart';
import '../../members/domain/member_model.dart';

class WorshipMinistryHelper {
  static const ministryName = 'Louvor';

  static Future<MinistryModel> ensureMinistry(MemberApi api) async {
    final ministries = await api.listMinistries();
    final existing = ministries.where((m) {
      final name = m.name.toLowerCase();
      return name.contains('louvor') || name.contains('worship') || name.contains('música') || name.contains('musica');
    }).toList();
    if (existing.isNotEmpty) return existing.first;
    return api.createMinistry(
      name: ministryName,
      description: 'Escala e músicos do ministério de louvor',
    );
  }
}
