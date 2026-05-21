import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/animated/fade_in.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_spacing.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  static final _googleSignIn = kIsWeb
      ? GoogleSignIn(scopes: ['email', 'profile'])
      : GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: const String.fromEnvironment(
            'GOOGLE_CLIENT_ID',
            defaultValue: '520104571386-kj462ur3tstcoprsftlnut4qm3nssc1l.apps.googleusercontent.com',
          ),
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              FadeIn(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.church,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),
                    Text(
                      'IPI Avaré',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Faça login para continuar',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (authState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    authState.error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              AppButton(
                label: 'Entrar com Google',
                icon: Icons.login,
                onPressed: authState.isLoading
                    ? null
                    : () => _handleGoogleSignIn(context, ref),
                isLoading: authState.isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Ao continuar, você concorda com nossos Termos de Uso',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(
      BuildContext context, WidgetRef ref) async {
    try {
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
              backgroundColor: AppColors.error,
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
