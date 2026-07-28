import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/bible_models.dart';

class BibleChapterScreen extends StatelessWidget {
  final String bookId;

  const BibleChapterScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final accent = AppColors.primary;
    final accentLight = accent.withValues(alpha: 0.12);

    final book = BibleBook.all.firstWhere((b) => b.id == bookId);
    final chapters = List.generate(book.chapters, (i) => i + 1);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          book.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${book.chapters} capítulos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
                Icon(Icons.menu_book_rounded, size: 16, color: accent),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.go(AppRoutes.bibleVerse(bookId, chapter)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF16161F)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        chapter.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF1A1A2E),
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
    );
  }
}
