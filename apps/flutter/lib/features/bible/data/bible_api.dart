import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/bible_models.dart';

const _abbrevToId = <String, String>{
  'Gn': 'GEN', 'Êx': 'EXO', 'Lv': 'LEV', 'Nm': 'NUM', 'Dt': 'DEU',
  'Js': 'JOS', 'Jz': 'JDG', 'Rt': 'RUT', '1Sm': '1SA', '2Sm': '2SA',
  '1Rs': '1KI', '2Rs': '2KI', '1Cr': '1CH', '2Cr': '2CH', 'Ed': 'EZR',
  'Ne': 'NEH', 'Et': 'EST', 'Jó': 'JOB', 'Sl': 'PSA', 'Pv': 'PRO',
  'Ec': 'ECC', 'Ct': 'SNG', 'Is': 'ISA', 'Jr': 'JER', 'Lm': 'LAM',
  'Ez': 'EZK', 'Dn': 'DAN', 'Os': 'HOS', 'Jl': 'JOL', 'Am': 'AMO',
  'Ob': 'OBA', 'Jn': 'JON', 'Mq': 'MIC', 'Na': 'NAM', 'Hc': 'HAB',
  'Sf': 'ZEP', 'Ag': 'HAG', 'Zc': 'ZEC', 'Ml': 'MAL',
  'Mt': 'MAT', 'Mc': 'MRK', 'Lc': 'LUK', 'Jo': 'JHN', 'At': 'ACT',
  'Rm': 'ROM', '1Co': '1CO', '2Co': '2CO', 'Gl': 'GAL', 'Ef': 'EPH',
  'Fp': 'PHP', 'Cl': 'COL', '1Ts': '1TH', '2Ts': '2TH', '1Tm': '1TI',
  '2Tm': '2TI', 'Tt': 'TIT', 'Fm': 'PHM', 'Hb': 'HEB', 'Tg': 'JAS',
  '1Pe': '1PE', '2Pe': '2PE', '1Jo': '1JN', '2Jo': '2JN', '3Jo': '3JN',
  'Jd': 'JUD', 'Ap': 'REV',
};

/// Asset key as declared in pubspec (same on mobile and web).
const _bibleAssetPath = 'assets/bible/naa/naa.json';

class BibleRepository {
  Map<String, Map<String, List<String>>>? _cache;

  Future<Map<String, Map<String, List<String>>>> _loadJson() async {
    if (_cache != null) return _cache!;

    final jsonStr = await rootBundle.loadString(_bibleAssetPath);
    final data = json.decode(jsonStr) as List<dynamic>;
    final result = <String, Map<String, List<String>>>{};

    for (final book in data) {
      final abbrev = book['abbrev'] as String;
      final bookId = _abbrevToId[abbrev] ?? abbrev;
      final chapters = book['chapters'] as List<dynamic>;
      final chapterMap = <String, List<String>>{};
      for (int i = 0; i < chapters.length; i++) {
        final verses = chapters[i] as List<dynamic>;
        chapterMap[(i + 1).toString()] = verses.cast<String>();
      }
      result[bookId] = chapterMap;
    }

    _cache = result;
    return result;
  }

  Future<List<String>> getChapterText(String bookId, int chapter) async {
    final bible = await _loadJson();
    final book = bible[bookId];
    if (book == null) return [];
    return book[chapter.toString()] ?? [];
  }

  Future<List<BibleVerse>> getVerses(String bookId, int chapter) async {
    final verses = await getChapterText(bookId, chapter);
    return verses.asMap().entries.map((e) {
      return BibleVerse(
        id: '$bookId.$chapter.${e.key + 1}',
        reference: '$chapter:${e.key + 1}',
        chapter: chapter,
        verse: e.key + 1,
        text: e.value,
      );
    }).toList();
  }

  Future<bool> hasBook(String bookId) async {
    final bible = await _loadJson();
    return bible.containsKey(bookId);
  }

  Future<bool> hasChapter(String bookId, int chapter) async {
    final bible = await _loadJson();
    final book = bible[bookId];
    return book?.containsKey(chapter.toString()) ?? false;
  }
}

final bibleRepositoryProvider = Provider<BibleRepository>((ref) => BibleRepository());
