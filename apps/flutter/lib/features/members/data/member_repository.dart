import '../../../core/offline/cache_keys.dart';
import '../../../core/offline/cached_result.dart';
import '../../../core/offline/local_cache.dart';
import '../../../core/offline/network_error.dart';
import '../domain/birthday_model.dart';
import '../domain/member_model.dart';
import 'member_api.dart';

class MemberRepository {
  final MemberApi _api;
  final LocalCache _cache;

  MemberRepository(this._api, this._cache);

  List<MemberModel>? peekListCache() {
    final cached = _cache.getList(CacheKeys.membersList);
    if (cached == null) return null;
    return cached.map(MemberModel.fromJson).toList();
  }

  MemberModel? peekDetailCache(String id) {
    final map = _cache.getMap(CacheKeys.memberDetail(id));
    if (map != null) return MemberModel.fromJson(map);

    final list = peekListCache();
    if (list == null) return null;
    try {
      return list.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<CachedResult<List<MemberModel>>> list({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
    String? role,
    String? ministryId,
  }) async {
    try {
      final items = await _api.list(
        page: page,
        limit: limit,
        status: status,
        search: search,
        role: role,
        ministryId: ministryId,
      );
      await _cache.setJson(
        CacheKeys.membersList,
        items.map(_toCacheJson).toList(),
      );
      for (final item in items) {
        await _cache.setJson(CacheKeys.memberDetail(item.id), _toCacheJson(item));
      }
      return CachedResult(items);
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      final cached = peekListCache();
      if (cached != null) return CachedResult(cached, fromCache: true);
      rethrow;
    }
  }

  Future<CachedResult<MemberModel>> getById(String id) async {
    try {
      final item = await _api.getById(id);
      await _cache.setJson(CacheKeys.memberDetail(id), _toCacheJson(item));
      return CachedResult(item);
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      final cached = peekDetailCache(id);
      if (cached != null) return CachedResult(cached, fromCache: true);
      rethrow;
    }
  }

  Future<MemberModel> create(Map<String, dynamic> data) => _api.create(data);

  Future<MemberModel> update(String id, Map<String, dynamic> data) =>
      _api.update(id, data);

  Future<List<MemberModel>> search(String query) => _api.search(query);

  Future<List<MinistryModel>> listMinistries() => _api.listMinistries();

  Future<MinistryModel> createMinistry({
    required String name,
    String? description,
  }) {
    return _api.createMinistry(name: name, description: description);
  }

  Future<BirthdayListResult> listBirthdays({String period = 'week'}) {
    return _api.listBirthdays(period: period);
  }

  Map<String, dynamic> _toCacheJson(MemberModel member) {
    return {
      'id': member.id,
      'userId': member.userId,
      'name': member.name,
      'email': member.email,
      'phone': member.phone,
      'avatar': member.avatar,
      'dateOfBirth': member.birthDate?.toIso8601String(),
      'gender': member.gender,
      'maritalStatus': member.maritalStatus,
      'status': member.status,
      'role': member.role,
      'ministryId': member.ministryId,
      if (member.ministryName != null)
        'ministry': {
          'id': member.ministryId,
          'name': member.ministryName,
        },
      'ministries': member.ministries,
      'baptismDate': member.baptismDate?.toIso8601String(),
      'baptismChurch': member.baptismChurch,
      'conversionDate': member.conversionDate?.toIso8601String(),
      'admissionDate': member.admissionDate?.toIso8601String(),
      'admissionType': member.admissionType,
      'isBaptized': member.isBaptized,
      'occupation': member.occupation,
      'notes': member.notes,
      if (member.address != null) 'address': member.address!.toJson(),
      'createdAt': member.createdAt.toIso8601String(),
    };
  }
}
