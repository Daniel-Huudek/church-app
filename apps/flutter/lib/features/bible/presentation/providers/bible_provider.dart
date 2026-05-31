import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/bible_api.dart';
import '../../domain/bible_models.dart';

class BibleChapterState {
  final List<String> verses;
  final bool loading;
  final String? error;
  final String bookName;
  final int chapter;
  final int totalChapters;

  const BibleChapterState({
    this.verses = const [],
    this.loading = true,
    this.error,
    this.bookName = '',
    this.chapter = 1,
    this.totalChapters = 1,
  });

  BibleChapterState copyWith({
    List<String>? verses,
    bool? loading,
    String? error,
    String? bookName,
    int? chapter,
    int? totalChapters,
  }) {
    return BibleChapterState(
      verses: verses ?? this.verses,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      totalChapters: totalChapters ?? this.totalChapters,
    );
  }
}

class BibleNotifier extends StateNotifier<BibleChapterState> {
  final BibleRepository _repo;

  BibleNotifier(this._repo) : super(const BibleChapterState());

  Future<void> loadChapter(String bookId, int chapter) async {
    state = state.copyWith(
      chapter: chapter,
      loading: true,
      error: null,
    );

    try {
      final book = BibleBook.all.firstWhere((b) => b.id == bookId);
      final verses = await _repo.getChapterText(bookId, chapter);

      state = BibleChapterState(
        verses: verses,
        loading: false,
        bookName: book.name,
        chapter: chapter,
        totalChapters: book.chapters,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Erro ao carregar capítulo: ${e.toString()}',
      );
    }
  }

  Future<void> nextChapter(String bookId) async {
    final next = state.chapter + 1;
    if (next <= state.totalChapters) {
      await loadChapter(bookId, next);
    }
  }

  Future<void> previousChapter(String bookId) async {
    final prev = state.chapter - 1;
    if (prev >= 1) {
      await loadChapter(bookId, prev);
    }
  }
}

final bibleChapterProvider =
    StateNotifierProvider.autoDispose<BibleNotifier, BibleChapterState>((ref) {
  final repo = ref.watch(bibleRepositoryProvider);
  return BibleNotifier(repo);
});
