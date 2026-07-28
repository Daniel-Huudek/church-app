import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/theme/app_theme.dart';
import 'core/network/auth_interceptor.dart';
import 'core/offline/offline_guard.dart';
import 'core/router/app_router.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/theme_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    ref.watch(mutationSyncBootstrapProvider);

    AuthInterceptor.onSessionExpired = () {
      ref.read(authProvider.notifier).clearSession();
    };

    return MaterialApp.router(
      title: 'IPI Avaré',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeState.themeMode,
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('pt', 'BR'),
    );
  }
}
