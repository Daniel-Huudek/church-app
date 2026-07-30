import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/hinario_models.dart';

/// Asset key as declared in pubspec (same on mobile and web).
const _hinarioAssetPath = 'assets/hinario/ctp.json';

class HinarioRepository {
  List<CtpHymn>? _cache;
  Map<String, CtpHymn>? _byNumber;

  Future<List<CtpHymn>> loadAll() async {
    if (_cache != null) return _cache!;

    final jsonStr = await rootBundle.loadString(_hinarioAssetPath);
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final hymns = (data['hymns'] as List<dynamic>)
        .map((e) => CtpHymn.fromJson(e as Map<String, dynamic>))
        .where((h) => h.number.isNotEmpty)
        .toList();

    _cache = hymns;
    _byNumber = {for (final h in hymns) h.number: h};
    return hymns;
  }

  Future<CtpHymn?> getByNumber(String number) async {
    await loadAll();
    return _byNumber?[number];
  }

  Future<int> indexOf(String number) async {
    final hymns = await loadAll();
    return hymns.indexWhere((h) => h.number == number);
  }
}

final hinarioRepositoryProvider = Provider<HinarioRepository>(
  (ref) => HinarioRepository(),
);
