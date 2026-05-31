import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/bible_models.dart';
import '../providers/bible_provider.dart';

class BibleVerseScreen extends ConsumerStatefulWidget {
  final String bookId;
  final int chapter;

  const BibleVerseScreen({
    super.key,
    required this.bookId,
    required this.chapter,
  });

  @override
  ConsumerState<BibleVerseScreen> createState() => _BibleVerseScreenState();
}

class _BibleVerseScreenState extends ConsumerState<BibleVerseScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(bibleChapterProvider.notifier).loadChapter(widget.bookId, widget.chapter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D14) : const Color(0xFFF8F6F1);
    final accent = const Color(0xFFC8A45C);
    final accentLight = accent.withValues(alpha: 0.12);

    final state = ref.watch(bibleChapterProvider);
    final book = BibleBook.all.firstWhere((b) => b.id == widget.bookId);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          '${book.name} ${widget.chapter}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.chevron_left, size: 22),
            onPressed: widget.chapter > 1
                ? () => context.go(AppRoutes.bibleVerse(widget.bookId, widget.chapter - 1))
                : null,
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, size: 22),
            onPressed: widget.chapter < book.chapters
                ? () => context.go(AppRoutes.bibleVerse(widget.bookId, widget.chapter + 1))
                : null,
          ),
        ],
      ),
      body: _buildBody(state, isDark, accent, accentLight, book),
    );
  }

  Widget _buildBody(BibleChapterState state, bool isDark, Color accent, Color accentLight, BibleBook book) {
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
              ElevatedButton(
                onPressed: () => ref.read(bibleChapterProvider.notifier).loadChapter(widget.bookId, widget.chapter),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.verses.isEmpty) {
      return Center(
        child: Text('Nenhum versículo encontrado.',
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white38 : Colors.black26)),
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: accentLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.verses.length} versículos',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.chapter > 1)
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.bibleVerse(widget.bookId, widget.chapter - 1)),
                      child: Text('‹ Cap. ${widget.chapter - 1}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: accent)),
                    ),
                  const SizedBox(width: 12),
                  if (widget.chapter < book.chapters)
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.bibleVerse(widget.bookId, widget.chapter + 1)),
                      child: Text('Cap. ${widget.chapter + 1} ›',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: accent)),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: state.verses.length,
            itemBuilder: (context, index) {
              final verseNum = index + 1;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go(AppRoutes.bibleVerseReader(widget.bookId, widget.chapter, verseNum)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF16161F) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      verseNum.toString(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
