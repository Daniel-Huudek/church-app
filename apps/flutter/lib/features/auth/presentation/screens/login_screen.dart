import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/google_sign_in_provider.dart';
import '../widgets/animated_logo.dart';
import '../widgets/google_button.dart';
import '../widgets/fade_slide_in.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final googleSignIn = ref.read(googleSignInProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
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
                      : () => _handleGoogleSignIn(context, ref, googleSignIn),
                ),
                if (authState.isLoading)
                  FadeSlideIn(
                    delay: 100,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Aguarde enquanto verificamos sua conta...',
                        style: TextStyle(
                          color: AppColors.neutral400,
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
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          authState.error!,
                          style: TextStyle(
                            color: AppColors.error,
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
      BuildContext context, WidgetRef ref, GoogleSignIn googleSignIn) async {
    try {
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) return;

      final authentication = await account.authentication;
      final token = authentication.idToken ?? authentication.accessToken;

      if (token != null) {
        await ref.read(authProvider.notifier).loginWithGoogle(token);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Erro ao obter token do Google'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      if (context.mounted) {
        final authState = ref.read(authProvider);
        if (authState.isAuthenticated) {
          context.go(AppRoutes.home);
        }
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer login: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
