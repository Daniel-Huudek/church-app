import '../../members/data/member_api.dart';
import '../../members/domain/member_model.dart';

class DeaconMinistryHelper {
  static const ministryName = 'Diáconos';

  static Future<MinistryModel> ensureMinistry(MemberApi api) async {
    final ministries = await api.listMinistries();
    final existing = ministries.where((m) {
      final name = m.name.toLowerCase();
      return name.contains('diácono') || name.contains('diacon');
    }).toList();
    if (existing.isNotEmpty) return existing.first;
    return api.createMinistry(
      name: ministryName,
      description: 'Escala e funções do diaconato',
    );
  }
}
