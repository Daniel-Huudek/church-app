import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../widgets/animated_logo.dart';
import '../widgets/google_button.dart';
import '../widgets/fade_slide_in.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb
        ? const String.fromEnvironment(
            'GOOGLE_WEB_CLIENT_ID',
            defaultValue:
                '520104571386-kj462ur3tstcoprsftlnut4qm3nssc1l.apps.googleusercontent.com',
          )
        : null,
    serverClientId: kIsWeb
        ? null
        : const String.fromEnvironment(
            'GOOGLE_WEB_CLIENT_ID',
            defaultValue:
                '520104571386-kj462ur3tstcoprsftlnut4qm3nssc1l.apps.googleusercontent.com',
          ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF008CFF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnimatedLogo(),
                const SizedBox(height: 64),
                GoogleButton(
                  loading: authState.isLoading,
                  onPressed: authState.isLoading
                      ? null
                      : () => _handleGoogleSignIn(context, ref),
                ),
                if (authState.isLoading)
                  FadeSlideIn(
                    delay: 100,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Aguarde enquanto verificamos sua conta...',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (authState.error != null)
                  FadeSlideIn(
                    delay: 0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF87171).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          authState.error!,
                          style: const TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ),
      bottomNavigationBar: SafeArea(
        child: FadeSlideIn(
          delay: 800,
          child: const Padding(
            padding: EdgeInsets.fromLTRB(32, 0, 32, 24),
            child: Text(
              'Ao continuar, você concorda com nossos Termos de Serviço e Política de Privacidade.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(
      BuildContext context, WidgetRef ref) async {
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) return;

      final authentication = await account.authentication;
      final token = authentication.idToken ?? authentication.accessToken;

      if (token != null) {
        await ref.read(authProvider.notifier).loginWithGoogle(token);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao obter token do Google'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }
      if (context.mounted) {
        final authState = ref.read(authProvider);
        if (authState.isAuthenticated) {
          context.go('/');
        }
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer login: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
