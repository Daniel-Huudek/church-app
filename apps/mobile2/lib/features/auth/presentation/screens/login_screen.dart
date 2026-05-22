import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../shared/providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb
        ? const String.fromEnvironment(
            'GOOGLE_CLIENT_ID',
            defaultValue:
                '520104571386-kj462ur3tstcoprsftlnut4qm3nssc1l.apps.googleusercontent.com',
          )
        : null,
    serverClientId: kIsWeb
        ? null
        : const String.fromEnvironment(
            'GOOGLE_CLIENT_ID',
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
                _AnimatedLogo(),
                const SizedBox(height: 64),
                _GoogleButton(
                  loading: authState.isLoading,
                  onPressed: authState.isLoading
                      ? null
                      : () => _handleGoogleSignIn(context, ref),
                ),
                if (authState.isLoading)
                  _FadeSlideIn(
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
                  _FadeSlideIn(
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
        child: _FadeSlideIn(
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

class _AnimatedLogo extends StatefulWidget {
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1.1)
            .chain(CurveTween(curve: const Interval(0, 0.66, curve: Curves.easeOutBack))),
        weight: 66,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: const Interval(0, 1, curve: Curves.easeOut))),
        weight: 34,
      ),
    ]).animate(_controller);
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 234,
            height: 234,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Sua igreja conectada',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatefulWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const _GoogleButton({this.loading = false, this.onPressed});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacityAnim.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            constraints: const BoxConstraints(minWidth: 200),
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/google.png',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    widget.loading ? 'Entrando...' : 'Entrar com Google',
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delay;

  const _FadeSlideIn({required this.child, this.delay = 0});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _slideAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacityAnim.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
