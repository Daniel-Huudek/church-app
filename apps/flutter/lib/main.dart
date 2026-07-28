import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/offline/local_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalCache.instance.init();
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
