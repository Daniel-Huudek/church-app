import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/utils/error_helper.dart';
import '../../data/activity_log_api.dart';
import '../../data/activity_log_model.dart';

final activityLogApiProvider = Provider<ActivityLogApi>((ref) {
  return ActivityLogApi(ref.read(apiClientProvider));
});

class ActivityLogListState {
  final List<ActivityLogModel> items;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final String? domain;
  final int page;
  final int totalPages;
  final bool hasMore;

  const ActivityLogListState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.domain,
    this.page = 1,
    this.totalPages = 1,
    this.hasMore = false,
  });

  ActivityLogListState copyWith({
    List<ActivityLogModel>? items,
    bool? loading,
    bool? loadingMore,
    String? error,
    String? domain,
    bool clearError = false,
    bool clearDomain = false,
    int? page,
    int? totalPages,
    bool? hasMore,
  }) {
    return ActivityLogListState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      domain: clearDomain ? null : (domain ?? this.domain),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final activityLogListProvider =
    StateNotifierProvider.autoDispose<ActivityLogListNotifier, ActivityLogListState>((ref) {
  return ActivityLogListNotifier(ref.read(activityLogApiProvider));
});

class ActivityLogListNotifier extends StateNotifier<ActivityLogListState> {
  final ActivityLogApi _api;

  ActivityLogListNotifier(this._api) : super(const ActivityLogListState(loading: true)) {
    load();
  }

  Future<void> load() async {
    await _fetch(domain: state.domain, clearDomain: state.domain == null);
  }

  Future<void> setDomain(String? domain) async {
    await _fetch(domain: domain, clearDomain: domain == null);
  }

  Future<void> _fetch({required String? domain, required bool clearDomain}) async {
    state = state.copyWith(
      loading: true,
      clearError: true,
      domain: domain,
      clearDomain: clearDomain,
      page: 1,
    );
    try {
      final page = await _api.list(page: 1, domain: domain);
      state = state.copyWith(
        items: page.items,
        loading: false,
        page: page.page,
        totalPages: page.totalPages,
        hasMore: page.page < page.totalPages,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: formatError(e));
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final page = await _api.list(page: nextPage, domain: state.domain);
      state = state.copyWith(
        items: [...state.items, ...page.items],
        loadingMore: false,
        page: page.page,
        totalPages: page.totalPages,
        hasMore: page.page < page.totalPages,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: formatError(e));
    }
  }
}
