import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/providers/async_state.dart';
import '../../data/website_api.dart';

final websiteApiProvider = Provider<WebsiteApi>((ref) {
  return WebsiteApi(ref.read(apiClientProvider));
});

final websiteContentProvider =
    StateNotifierProvider.autoDispose<WebsiteContentNotifier, AsyncState<Map<String, dynamic>>>(
  (ref) => WebsiteContentNotifier(ref.read(websiteApiProvider)),
);

class WebsiteContentNotifier extends StateNotifier<AsyncState<Map<String, dynamic>>> {
  WebsiteContentNotifier(this._api)
      : super(const AsyncState(data: <String, dynamic>{}, loading: true)) {
    load();
  }

  final WebsiteApi _api;

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final payload = await _api.getAdmin();
      final content = Map<String, dynamic>.from(
        (payload['content'] as Map?)?.cast<String, dynamic>() ?? payload,
      );
      state = AsyncState(data: content, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> save(Map<String, dynamic> content) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final payload = await _api.save(content);
      final saved = Map<String, dynamic>.from(
        (payload['content'] as Map?)?.cast<String, dynamic>() ?? content,
      );
      state = AsyncState(data: saved, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }
}
