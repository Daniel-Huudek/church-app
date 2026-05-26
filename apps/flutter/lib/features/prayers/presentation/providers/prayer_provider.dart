import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/prayer_api.dart';
import '../../domain/prayer_model.dart';
import '../../../../shared/providers/async_state.dart';
import '../../../../shared/utils/error_helper.dart';

final prayerApiProvider = Provider<PrayerApi>((ref) {
  return PrayerApi(ref.read(apiClientProvider));
});

final prayerFeedProvider =
    StateNotifierProvider<PrayerFeedNotifier, AsyncState<List<PrayerModel>>>((ref) {
  return PrayerFeedNotifier(ref.read(prayerApiProvider));
});

class PrayerFeedNotifier extends StateNotifier<AsyncState<List<PrayerModel>>> {
  final PrayerApi _api;

  PrayerFeedNotifier(this._api) : super(const AsyncState(data: []));

  Future<void> loadFeed() async {
    state = AsyncState(data: state.data, loading: true);
    try {
      final prayers = await _api.list();
      state = AsyncState(data: prayers, loading: false);
    } catch (e) {
      state = AsyncState(
        data: state.data,
        loading: false,
        error: formatError(e),
      );
    }
  }

  Future<void> loadMine() async {
    state = AsyncState(data: state.data, loading: true);
    try {
      final prayers = await _api.getMy();
      state = AsyncState(data: prayers, loading: false);
    } catch (e) {
      state = AsyncState(
        data: state.data,
        loading: false,
        error: formatError(e),
      );
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      await _api.create(data);
      await loadFeed();
    } catch (e) {
      state = AsyncState(data: state.data, loading: false, error: formatError(e));
    }
  }
}

class PrayerDetailState {
  final PrayerModel? prayer;
  final List<PrayerComment> comments;
  final bool loading;
  final String? error;
  final bool posting;

  const PrayerDetailState({
    this.prayer,
    this.comments = const [],
    this.loading = true,
    this.error,
    this.posting = false,
  });
}

final prayerDetailProvider =
    StateNotifierProvider.family<PrayerDetailNotifier, PrayerDetailState, String>(
        (ref, id) {
  return PrayerDetailNotifier(ref.read(prayerApiProvider), id);
});

class PrayerDetailNotifier extends StateNotifier<PrayerDetailState> {
  final PrayerApi _api;
  final String _id;

  PrayerDetailNotifier(this._api, this._id) : super(const PrayerDetailState()) {
    load();
  }

  Future<void> load() async {
    state = PrayerDetailState(prayer: state.prayer, loading: true);
    try {
      final prayer = await _api.getById(_id);
      final comments = prayer.comments;
      state = PrayerDetailState(
        prayer: prayer,
        comments: comments,
        loading: false,
      );
    } catch (e) {
      state = PrayerDetailState(
        loading: false,
        error: formatError(e),
      );
    }
  }

  Future<void> addComment(String content, {String? userName, String? userAvatar}) async {
    if (content.trim().isEmpty) return;
    final tempComment = PrayerComment(
      id: '',
      prayerId: _id,
      authorId: '',
      authorName: userName ?? 'Você',
      authorAvatar: userAvatar,
      content: content.trim(),
      createdAt: DateTime.now(),
    );
    state = PrayerDetailState(
      prayer: state.prayer,
      comments: [tempComment, ...state.comments],
      loading: false,
      posting: true,
    );
    try {
      var comment = await _api.addComment(_id, content.trim());
      if (comment.authorName.isEmpty) {
        comment = PrayerComment(
          id: comment.id,
          prayerId: comment.prayerId,
          authorId: comment.authorId,
          authorName: userName ?? 'Você',
          authorAvatar: userAvatar ?? comment.authorAvatar,
          content: comment.content,
          createdAt: comment.createdAt,
        );
      }
      state = PrayerDetailState(
        prayer: state.prayer?.copyWith(commentsCount: (state.prayer!.commentsCount + 1)),
        comments: [
          for (final c in state.comments)
            if (c.id.isEmpty && c.content == content.trim()) comment else c,
        ],
        loading: false,
      );
    } catch (e) {
      state = PrayerDetailState(
        prayer: state.prayer,
        comments: state.comments.where((c) => c.id.isNotEmpty || c.content != content.trim()).toList(),
        loading: false,
        error: formatError(e),
      );
    }
  }

  Future<void> toggleReaction(String type) async {
    try {
      await _api.toggleReaction(_id, type);
      await load();
    } catch (e) {
      state = PrayerDetailState(prayer: state.prayer, comments: state.comments, loading: false, error: formatError(e));
    }
  }
}
