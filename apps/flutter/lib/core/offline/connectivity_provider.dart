import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true` when at least one network interface is available (not a guarantee of internet).
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  List<ConnectivityResult> current;
  try {
    current = await connectivity.checkConnectivity();
  } catch (_) {
    current = [ConnectivityResult.none];
  }
  yield _hasConnection(current);

  yield* connectivity.onConnectivityChanged.map(_hasConnection);
});

bool _hasConnection(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.any((r) => r != ConnectivityResult.none);
}
