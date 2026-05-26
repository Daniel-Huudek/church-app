import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../domain/worship_models.dart';

class SongCard extends StatelessWidget {
  final Song song; final VoidCallback? onFavorite; final bool isFavorite; final VoidCallback? onTap;
  const SongCard({super.key, required this.song, this.onFavorite, this.isFavorite = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E) : Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)).withValues(alpha: 0.5))),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primary.withValues(alpha: 0.3)]), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Icon(Icons.music_note_rounded, color: Colors.white.withValues(alpha: 0.9), size: 20))),
          const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(song.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827))),
            const SizedBox(height: 2),
            Row(children: [
              if (song.artist != null) ...[Text(song.artist!, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))), const SizedBox(width: 8)],
              if (song.key != null) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(song.key!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5))),
            ]),
          ])),
          if (onFavorite != null) IconButton(icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded, size: 20, color: isFavorite ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB))), onPressed: onFavorite, visualDensity: VisualDensity.compact),
        ]),
      ),
    );
  }
}
