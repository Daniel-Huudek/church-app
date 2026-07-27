import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/bible_api.dart';
import '../../domain/bible_models.dart';

class DailyVerseRef {
  final String bookId;
  final int chapter;
  final int verse;

  const DailyVerseRef({
    required this.bookId,
    required this.chapter,
    required this.verse,
  });
}

class VerseOfTheDay {
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  final String reference;

  const VerseOfTheDay({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.reference,
  });
}

/// Curated encouraging verses; rotates by day of year.
const dailyVerseRefs = <DailyVerseRef>[
  DailyVerseRef(bookId: 'PSA', chapter: 23, verse: 1),
  DailyVerseRef(bookId: 'PSA', chapter: 46, verse: 1),
  DailyVerseRef(bookId: 'PSA', chapter: 91, verse: 1),
  DailyVerseRef(bookId: 'PSA', chapter: 119, verse: 105),
  DailyVerseRef(bookId: 'PRO', chapter: 3, verse: 5),
  DailyVerseRef(bookId: 'PRO', chapter: 3, verse: 6),
  DailyVerseRef(bookId: 'ISA', chapter: 41, verse: 10),
  DailyVerseRef(bookId: 'JER', chapter: 29, verse: 11),
  DailyVerseRef(bookId: 'MAT', chapter: 5, verse: 16),
  DailyVerseRef(bookId: 'MAT', chapter: 6, verse: 33),
  DailyVerseRef(bookId: 'MAT', chapter: 11, verse: 28),
  DailyVerseRef(bookId: 'JHN', chapter: 3, verse: 16),
  DailyVerseRef(bookId: 'JHN', chapter: 14, verse: 6),
  DailyVerseRef(bookId: 'JHN', chapter: 14, verse: 27),
  DailyVerseRef(bookId: 'ROM', chapter: 8, verse: 28),
  DailyVerseRef(bookId: 'ROM', chapter: 12, verse: 2),
  DailyVerseRef(bookId: 'PHP', chapter: 4, verse: 6),
  DailyVerseRef(bookId: 'PHP', chapter: 4, verse: 7),
  DailyVerseRef(bookId: 'PHP', chapter: 4, verse: 13),
  DailyVerseRef(bookId: 'GAL', chapter: 5, verse: 22),
  DailyVerseRef(bookId: 'EPH', chapter: 2, verse: 8),
  DailyVerseRef(bookId: 'EPH', chapter: 3, verse: 20),
  DailyVerseRef(bookId: 'COL', chapter: 3, verse: 23),
  DailyVerseRef(bookId: '1TH', chapter: 5, verse: 16),
  DailyVerseRef(bookId: '1TH', chapter: 5, verse: 17),
  DailyVerseRef(bookId: '1TH', chapter: 5, verse: 18),
  DailyVerseRef(bookId: 'HEB', chapter: 11, verse: 1),
  DailyVerseRef(bookId: 'JAS', chapter: 1, verse: 5),
  DailyVerseRef(bookId: '1PE', chapter: 5, verse: 7),
  DailyVerseRef(bookId: '1JN', chapter: 4, verse: 8),
];

DailyVerseRef verseRefForDate(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  return dailyVerseRefs[dayOfYear % dailyVerseRefs.length];
}

final verseOfTheDayProvider = FutureProvider.autoDispose<VerseOfTheDay>((ref) async {
  final repo = ref.watch(bibleRepositoryProvider);
  final refVerse = verseRefForDate(DateTime.now());
  final book = BibleBook.all.firstWhere((b) => b.id == refVerse.bookId);
  final verses = await repo.getChapterText(refVerse.bookId, refVerse.chapter);
  final index = refVerse.verse - 1;
  final text = (index >= 0 && index < verses.length)
      ? verses[index]
      : 'Carregando versículo...';

  return VerseOfTheDay(
    bookId: refVerse.bookId,
    bookName: book.name,
    chapter: refVerse.chapter,
    verse: refVerse.verse,
    text: text,
    reference: '${book.name} ${refVerse.chapter}:${refVerse.verse}',
  );
});
