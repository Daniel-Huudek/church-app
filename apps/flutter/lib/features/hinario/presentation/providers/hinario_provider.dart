import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/hinario_repository.dart';
import '../../domain/hinario_models.dart';

final hinarioListProvider = FutureProvider<List<CtpHymn>>((ref) {
  return ref.watch(hinarioRepositoryProvider).loadAll();
});

final hinarioByNumberProvider =
    FutureProvider.family<CtpHymn?, String>((ref, number) {
  return ref.watch(hinarioRepositoryProvider).getByNumber(number);
});
