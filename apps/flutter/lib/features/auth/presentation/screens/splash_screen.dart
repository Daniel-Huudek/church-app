import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
    _opacityAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    );
    _scaleController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _pulseController.repeat(reverse: true);
    });

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        final auth = ref.read(authProvider);
        if (auth.isAuthenticated) {
          context.go('/');
        } else {
          context.go('/login');
        }
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        color: const Color(0xFF0A0A0F),
        child: Stack(
          children: [
            DecorativeCircle(
              size: 200, left: size.width * 0.05, top: size.height * 0.08, delay: 200,
            ),
            DecorativeCircle(
              size: 140, left: size.width * 0.7, top: size.height * 0.15, delay: 400,
            ),
            DecorativeCircle(
              size: 100, left: size.width * 0.1, top: size.height * 0.6, delay: 600,
            ),
            DecorativeCircle(
              size: 160, left: size.width * 0.65, top: size.height * 0.65, delay: 300,
            ),
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: child,
                ),
                child: AnimatedBuilder(
                  animation: _scaleController,
                  builder: (context, child) => Opacity(
                    opacity: _opacityAnim.value,
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: child,
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 160,
                    height: 160,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DecorativeCircle extends StatefulWidget {
  final double size;
  final double left;
  final double top;
  final int delay;

  const DecorativeCircle({
    super.key,
    required this.size,
    required this.left,
    required this.top,
    required this.delay,
  });

  @override
  State<DecorativeCircle> createState() => _DecorativeCircleState();
}

class _DecorativeCircleState extends State<DecorativeCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacityAnim = Tween<double>(begin: 0, end: 0.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scaleAnim = Tween<double>(begin: 0, end: 1).animate(
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
    return Positioned(
      left: widget.left,
      top: widget.top,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _opacityAnim.value,
          child: Transform.scale(scale: _scaleAnim.value, child: child),
        ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color.fromRGBO(196, 181, 253, 0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
