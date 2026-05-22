import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../domain/worship_models.dart';
import '../screens/playlist_detail_screen.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  const PlaylistCard({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final songCount = playlist.songs?.length ?? 0;
    final duration = playlist.totalDuration;
    final gradientColors = [AppColors.primary, const Color(0xFF6366F1), const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFFEC4899)];
    final color = gradientColors[playlist.name.length % gradientColors.length];

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistId: playlist.id))),
      child: SizedBox(
        width: 170,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 170, height: 170, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)]), borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Stack(children: [
              Positioned(right: 12, bottom: 12, child: Icon(Icons.queue_music_rounded, color: Colors.white.withValues(alpha: 0.2), size: 64)),
              Positioned(right: 14, bottom: 14, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]),
                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22))),
              Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Spacer(), Text(playlist.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3), maxLines: 2, overflow: TextOverflow.ellipsis)])),
            ]),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.music_note_outlined, size: 11, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
            const SizedBox(width: 4), Text('$songCount músicas', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
            if (duration > 0) ...[const SizedBox(width: 6), Container(width: 2, height: 2, decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))), const SizedBox(width: 6),
              Icon(Icons.timer_outlined, size: 11, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)), const SizedBox(width: 4), Text('${(duration / 60).ceil()}min', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)))],
          ]),
        ]),
      ),
    );
  }
}
