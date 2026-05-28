import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../domain/worship_models.dart';
import '../providers/worship_provider.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: playlistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar playlist: $e')),
        data: (playlists) {
          final playlist = playlists.where((p) => p.id == playlistId).firstOrNull;
          if (playlist == null) {
            return const Center(child: Text('Playlist não encontrada'));
          }
          final songs = playlist.songs ?? [];
          final duration = playlist.totalDuration;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(playlist.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
              if (playlist.description != null) ...[
                const SizedBox(height: 8),
                Text(playlist.description!, style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.music_note_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('${songs.length} músicas', style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                if (duration > 0) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('${(duration / 60).ceil()}min', style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                ],
              ]),
              const SizedBox(height: 24),
              if (songs.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text('Nenhuma música nesta playlist', style: TextStyle(fontSize: 16, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)),
                ))
              else
                ...songs.asMap().entries.map((entry) => _SongTile(
                  index: entry.key,
                  song: entry.value.song,
                  transpose: entry.value.transpose,
                  notes: entry.value.notes,
                  isDark: isDark,
                )),
            ],
          );
        },
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final int index;
  final Song song;
  final int transpose;
  final String? notes;
  final bool isDark;

  const _SongTile({
    required this.index,
    required this.song,
    required this.transpose,
    this.notes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('${index + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                if (song.artist != null)
                  Text(song.artist!, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                if (notes != null && notes!.isNotEmpty)
                  Text(notes!, style: TextStyle(fontSize: 12, color: AppColors.primary, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          if (song.key != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(song.key!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  if (transpose != 0)
                    Text(' ($transpose)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary.withValues(alpha: 0.7))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
