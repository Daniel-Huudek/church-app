import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import 'activity_log_model.dart';

class ActivityLogPage {
  final List<ActivityLogModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const ActivityLogPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}

class ActivityLogApi {
  final ApiClient _client;

  ActivityLogApi(this._client);

  Future<ActivityLogPage> list({
    int page = 1,
    int limit = 30,
    String? domain,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (domain != null && domain.isNotEmpty) {
      query['domain'] = domain;
    }

    final response = await _client.get(
      ApiConfig.activityLogs,
      queryParameters: query,
    );
    final map = response.data as Map<String, dynamic>;
    final payload = map['data'] as Map<String, dynamic>? ?? {};
    final rawItems = payload['data'] as List<dynamic>? ?? const [];
    return ActivityLogPage(
      items: rawItems
          .map((e) => ActivityLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (payload['total'] as num?)?.toInt() ?? rawItems.length,
      page: (payload['page'] as num?)?.toInt() ?? page,
      limit: (payload['limit'] as num?)?.toInt() ?? limit,
      totalPages: (payload['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
