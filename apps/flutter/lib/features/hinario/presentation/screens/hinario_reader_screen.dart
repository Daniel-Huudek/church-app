import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/hinario_models.dart';
import '../providers/hinario_provider.dart';

class HinarioReaderScreen extends ConsumerStatefulWidget {
  final String number;

  const HinarioReaderScreen({super.key, required this.number});

  @override
  ConsumerState<HinarioReaderScreen> createState() =>
      _HinarioReaderScreenState();
}

class _HinarioReaderScreenState extends ConsumerState<HinarioReaderScreen> {
  late String _number;
  double _fontSize = 20;

  @override
  void initState() {
    super.initState();
    _number = widget.number;
  }

  @override
  void didUpdateWidget(covariant HinarioReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) {
      _number = widget.number;
    }
  }

  void _goToNumber(String number) {
    context.go(AppRoutes.hinarioHymn(number));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final accent = AppColors.primary;
    final hymnsAsync = ref.watch(hinarioListProvider);

    return hymnsAsync.when(
      loading: () => Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: bg),
        body: const Center(child: Text('Erro ao carregar o hinário.')),
      ),
      data: (hymns) {
        final index = hymns.indexWhere((h) => h.number == _number);
        if (index < 0) {
          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              surfaceTintColor: Colors.transparent,
              title: const Text('Hinário'),
            ),
            body: Center(
              child: Text(
                'Hino $_number não encontrado.',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          );
        }

        final hymn = hymns[index];
        final hasPrev = index > 0;
        final hasNext = index < hymns.length - 1;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: GestureDetector(
              onTap: () => _showNumberPicker(context, hymns, accent, isDark),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      hymn.displayTitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ],
              ),
            ),
            centerTitle: true,
            backgroundColor: bg,
            surfaceTintColor: Colors.transparent,
            foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
            elevation: 0,
            actions: [
              if (hymn.copyright != null ||
                  hymn.reference != null ||
                  hymn.history != null)
                IconButton(
                  icon: Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  onPressed: () => _showInfo(context, hymn, isDark, accent),
                ),
              PopupMenuButton<double>(
                icon: Icon(
                  Icons.text_fields_rounded,
                  size: 18,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                onSelected: (v) => setState(() => _fontSize = v),
                itemBuilder: (_) => [16, 18, 20, 22, 24, 28, 32]
                    .map(
                      (s) => PopupMenuItem(
                        value: s.toDouble(),
                        child: Text(
                          '${s}pt',
                          style: TextStyle(
                            fontSize: s.toDouble(),
                            fontWeight: _fontSize == s
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final v = details.primaryVelocity;
                    if (v == null) return;
                    if (v < -80 && hasNext) {
                      _goToNumber(hymns[index + 1].number);
                    } else if (v > 80 && hasPrev) {
                      _goToNumber(hymns[index - 1].number);
                    }
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Hino ${hymn.number}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: accent,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        SelectableText(
                          hymn.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _fontSize + 2,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SelectableText(
                          hymn.lyrics,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _fontSize,
                            height: 1.75,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.88)
                                : const Color(0xFF1A1A2E).withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16161F) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavButton(
                          label: 'Anterior',
                          icon: Icons.arrow_back_ios_new_rounded,
                          iconLeading: true,
                          enabled: hasPrev,
                          accent: accent,
                          isDark: isDark,
                          onTap: hasPrev
                              ? () => _goToNumber(hymns[index - 1].number)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _showNumberPicker(context, hymns, accent, isDark),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: accent.withValues(alpha: 0.15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hymn.number,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.swap_vert_rounded,
                                    size: 18, color: accent),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NavButton(
                          label: 'Próximo',
                          icon: Icons.arrow_forward_ios_rounded,
                          iconLeading: false,
                          enabled: hasNext,
                          accent: accent,
                          isDark: isDark,
                          onTap: hasNext
                              ? () => _goToNumber(hymns[index + 1].number)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNumberPicker(
    BuildContext context,
    List<CtpHymn> hymns,
    Color accent,
    bool isDark,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF16161F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Selecionar hino',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: hymns.length,
                    itemBuilder: (_, i) {
                      final hymn = hymns[i];
                      final selected = hymn.number == _number;
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.pop(ctx);
                          _goToNumber(hymn.number);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? accent.withValues(alpha: 0.18)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? accent
                                  : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            hymn.number,
                            style: TextStyle(
                              fontSize: hymn.number.length > 3 ? 12 : 15,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? accent
                                  : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF1A1A2E)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInfo(
    BuildContext context,
    CtpHymn hymn,
    bool isDark,
    Color accent,
  ) {
    final parts = <String>[];
    if (hymn.reference != null && hymn.reference!.isNotEmpty) {
      parts.add('Glossário\n${hymn.reference}');
    }
    if (hymn.history != null && hymn.history!.isNotEmpty) {
      parts.add('Histórico\n${hymn.history}');
    }
    if (hymn.copyright != null && hymn.copyright!.isNotEmpty) {
      parts.add('Copyright\n${hymn.copyright}');
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF16161F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hymn.displayTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  parts.join('\n\n'),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
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

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool iconLeading;
  final bool enabled;
  final Color accent;
  final bool isDark;
  final VoidCallback? onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.iconLeading,
    required this.enabled,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        enabled ? accent : (isDark ? Colors.white24 : Colors.black12);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: enabled ? accent.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconLeading) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (!iconLeading) ...[
                const SizedBox(width: 6),
                Icon(icon, size: 18, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
