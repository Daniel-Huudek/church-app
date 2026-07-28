import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/bible_models.dart';
import '../providers/bible_provider.dart';

class BibleVerseReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final int chapter;
  final int verse;

  const BibleVerseReaderScreen({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.verse,
  });

  @override
  ConsumerState<BibleVerseReaderScreen> createState() => _BibleVerseReaderScreenState();
}

class _BibleVerseReaderScreenState extends ConsumerState<BibleVerseReaderScreen> {
  late String _bookId;
  late int _chapter;
  late int _verse;
  double _fontSize = 22;

  @override
  void initState() {
    super.initState();
    _bookId = widget.bookId;
    _chapter = widget.chapter;
    _verse = widget.verse;
    _load();
  }

  void _load() {
    Future.microtask(() {
      ref.read(bibleChapterProvider.notifier).loadChapter(_bookId, _chapter);
    });
  }

  void _goToVerse(int v) {
    setState(() {
      _verse = v;
    });
  }

  void _goToChapter(int ch) {
    setState(() {
      _chapter = ch;
      _verse = 1;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final accent = AppColors.primary;
    final state = ref.watch(bibleChapterProvider);
    final book = BibleBook.all.firstWhere((b) => b.id == _bookId);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showChapterPicker(context, book, isDark, accent),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${book.name} $_chapter:$_verse',
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
          PopupMenuButton<double>(
            icon: Icon(Icons.text_fields_rounded, size: 18,
              color: isDark ? Colors.white60 : Colors.black54),
            onSelected: (v) => setState(() => _fontSize = v),
            itemBuilder: (_) => [16, 18, 20, 22, 24, 28, 32, 36].map((s) =>
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
      body: _buildBody(state, isDark, bg, accent, book),
    );
  }

  Widget _buildBody(BibleChapterState state, bool isDark, Color bg, Color accent, BibleBook book) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null || state.verses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: isDark ? Colors.white30 : Colors.black26),
              const SizedBox(height: 16),
              Text(state.error ?? 'Nenhum conteúdo encontrado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: isDark ? Colors.white60 : Colors.black54)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    final totalVerses = state.verses.length;
    final hasPrev = _verse > 1;
    final hasNext = _verse < totalVerses;
    final currentText = _verse <= totalVerses ? state.verses[_verse - 1] : '';

    return Column(
      children: [
        // Verse text area with swipe
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -80 && hasNext) {
                  setState(() => _verse++);
                } else if (details.primaryVelocity! > 80 && hasPrev) {
                  setState(() => _verse--);
                }
              }
            },
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Chapter:Verse label
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${book.name} $_chapter:$_verse',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: accent,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    // Verse text
                    if (currentText.isNotEmpty)
                      SelectableText(
                        currentText,
                        style: TextStyle(
                          fontSize: _fontSize,
                          height: 1.8,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.88)
                              : const Color(0xFF1A1A2E).withValues(alpha: 0.88),
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bottom verse navigation bar
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
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
                // Previous verse
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: hasPrev ? () => setState(() => _verse--) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: hasPrev ? accent.withValues(alpha: 0.1) : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: hasPrev ? accent : (isDark ? Colors.white24 : Colors.black12),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Anterior',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: hasPrev ? accent : (isDark ? Colors.white24 : Colors.black12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Verse number picker
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showVersePicker(context, accent, isDark, totalVerses),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: accent.withValues(alpha: 0.15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_verse',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.swap_vert_rounded, size: 18, color: accent),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Next verse
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: hasNext ? () => setState(() => _verse++) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: hasNext ? accent.withValues(alpha: 0.1) : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Próximo',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: hasNext ? accent : (isDark ? Colors.white24 : Colors.black12),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: hasNext ? accent : (isDark ? Colors.white24 : Colors.black12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showVersePicker(BuildContext context, Color accent, bool isDark, int total) {
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
            Container(width: 36, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$_verse de $total',
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
                itemCount: total,
                itemBuilder: (ctx, i) {
                  final v = i + 1;
                  final isCurrent = v == _verse;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.pop(ctx);
                        _goToVerse(v);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? accent
                              : (isDark ? AppColors.darkBg : AppColors.lightSurface),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          v.toString(),
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

  void _showChapterPicker(BuildContext context, BibleBook book, bool isDark, Color accent) {
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
            Container(width: 36, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Capítulo $_chapter de ${book.chapters}',
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
                        _goToChapter(ch);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? accent
                              : (isDark ? AppColors.darkBg : AppColors.lightSurface),
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
