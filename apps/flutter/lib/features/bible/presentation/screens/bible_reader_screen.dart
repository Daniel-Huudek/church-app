import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../domain/bible_models.dart';
import '../providers/bible_provider.dart';

class BibleReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final int chapter;

  const BibleReaderScreen({
    super.key,
    required this.bookId,
    required this.chapter,
  });

  @override
  ConsumerState<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends ConsumerState<BibleReaderScreen> {
  late String _bookId;
  late int _chapter;
  double _fontSize = 18;

  @override
  void initState() {
    super.initState();
    _bookId = widget.bookId;
    _chapter = widget.chapter;
    _load();
  }

  void _load() {
    Future.microtask(() {
      ref.read(bibleChapterProvider.notifier).loadChapter(_bookId, _chapter);
    });
  }

  void _goChapter(int ch) {
    setState(() {
      _chapter = ch;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final state = ref.watch(bibleChapterProvider);
    final book = BibleBook.all.firstWhere((b) => b.id == _bookId);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showChapterPicker(context, book),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${book.name} $_chapter',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18,
                color: isDark ? Colors.white60 : Colors.black54),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          _navBtn(Icons.chevron_left, _chapter > 1, () => _goChapter(_chapter - 1)),
          _navBtn(Icons.chevron_right, _chapter < book.chapters, () => _goChapter(_chapter + 1)),
          PopupMenuButton<double>(
            icon: Icon(Icons.text_fields_rounded, size: 18,
              color: isDark ? Colors.white60 : Colors.black54),
            onSelected: (v) => setState(() => _fontSize = v),
            itemBuilder: (_) => [14, 16, 18, 20, 22, 24, 28].map((s) =>
              PopupMenuItem(
                value: s.toDouble(),
                child: Text('${s}pt', style: TextStyle(
                  fontSize: s.toDouble(),
                  fontWeight: _fontSize == s ? FontWeight.w700 : FontWeight.w400,
                )),
              ),
            ).toList(),
          ),
        ],
      ),
      body: _buildBody(state, isDark, book),
    );
  }

  Widget _navBtn(IconData icon, bool enabled, VoidCallback onTap) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: enabled ? onTap : null,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? (dark ? Colors.white24 : Colors.black12)
              : (dark ? Colors.white70 : Colors.black54)),
      ),
    );
  }

  Widget _buildBody(BibleChapterState state, bool isDark, BibleBook book) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: isDark ? Colors.white30 : Colors.black26),
              const SizedBox(height: 16),
              Text(state.error!, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: isDark ? Colors.white60 : Colors.black54)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    if (state.verses.isEmpty) {
      return Center(
        child: Text('Nenhum conteúdo encontrado.',
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white38 : Colors.black26)),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100 && _chapter < book.chapters) {
            _goChapter(_chapter + 1);
          } else if (details.primaryVelocity! > 100 && _chapter > 1) {
            _goChapter(_chapter - 1);
          }
        }
      },
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark ? AppColors.darkBg : AppColors.lightSurface,
                      Colors.transparent,
                      Colors.transparent,
                      isDark ? AppColors.darkBg : AppColors.lightSurface,
                    ],
                    stops: const [0.0, 0.03, 0.95, 1.0],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstOut,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    itemCount: state.verses.length,
                    itemBuilder: (context, index) {
                      final verseNum = index + 1;
                      final verseText = state.verses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$verseNum ',
                                style: TextStyle(
                                  fontSize: _fontSize * 0.55,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  height: 1.8,
                                ),
                              ),
                              TextSpan(
                                text: verseText,
                                style: TextStyle(
                                  fontSize: _fontSize,
                                  height: 1.8,
                                  fontWeight: FontWeight.w400,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : const Color(0xFF1A1A2E).withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          _bottomBar(book, isDark),
        ],
      ),
    );
  }

  Widget _bottomBar(BibleBook book, bool isDark) {
    final accent = AppColors.primary;
    final progress = _chapter / book.chapters;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161F) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 22),
              onPressed: _chapter > 1 ? () => _goChapter(_chapter - 1) : null,
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith((s) =>
                  s.contains(WidgetState.disabled)
                      ? (isDark ? Colors.white24 : Colors.black12)
                      : accent),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _showChapterPicker(context, book),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: accent.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(accent),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capítulo $_chapter de ${book.chapters}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 22),
              onPressed: _chapter < book.chapters ? () => _goChapter(_chapter + 1) : null,
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith((s) =>
                  s.contains(WidgetState.disabled)
                      ? (isDark ? Colors.white24 : Colors.black12)
                      : accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChapterPicker(BuildContext context, BibleBook book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF16161F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$_chapter de ${book.chapters}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.2,
                ),
                itemCount: book.chapters,
                itemBuilder: (ctx, i) {
                  final ch = i + 1;
                  final isCurrent = ch == _chapter;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.pop(ctx);
                        _goChapter(ch);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkBg
                                  : AppColors.lightSurface),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          ch.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent
                                ? Colors.white
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
