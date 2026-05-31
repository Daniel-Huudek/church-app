import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/worship_api.dart';
import '../providers/worship_provider.dart';

class FetchSongScreen extends ConsumerStatefulWidget {
  const FetchSongScreen({super.key});

  @override
  ConsumerState<FetchSongScreen> createState() => _FetchSongScreenState();
}

class _FetchSongScreenState extends ConsumerState<FetchSongScreen> {
  late final WorshipApi _worshipApi;
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  List<Map<String, dynamic>>? _results;
  String? _error;

  @override
  void initState() {
    super.initState();
    _worshipApi = WorshipApi(ref.read(apiClientProvider));
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _results = null;
      _error = null;
    });

    try {
      final results = await _worshipApi.searchSongs(query);
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _searching = false;
      });
    }
  }

  Future<void> _selectSong(Map<String, dynamic> song) async {
    try {
      await _worshipApi.createSong({
        'title': song['title'] as String? ?? '',
        'artist': song['artist'] as String? ?? '',
        if (song['lyrics'] != null) 'lyrics': song['lyrics'] as String,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Música salva no repertório!', style: TextStyle(fontSize: 14))),
            ]),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            duration: const Duration(seconds: 3),
          ),
        );
        ref.invalidate(songsProvider);
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary, size: 24),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Buscar Música',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.lightText,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(isDark),
          const SizedBox(height: 16),
          Expanded(
            child: _buildContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorderLight : AppColors.lightBorderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.neutral50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _search(),
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.lightText),
                decoration: InputDecoration(
                  hintText: 'Nome da música...',
                  hintStyle: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _searching ? null : _search,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _searching
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Buscar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _error!.replaceFirst('AppError: ', ''),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.error),
              ),
            ],
          ),
        ),
      );
    }

    if (_results == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note_rounded, size: 48, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
            const SizedBox(height: 16),
              Text(
                'Busque por uma música\nno Deezer ou YouTube',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, height: 1.5),
              ),
          ],
        ),
      );
    }

    if (_results!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
            const SizedBox(height: 16),
            Text(
              'Nenhuma música encontrada',
              style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: _results!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildResultCard(_results![i], isDark),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> song, bool isDark) {
    final source = song['source'] as String? ?? 'deezer';
    final title = song['title'] as String? ?? '';
    final artist = song['artist'] as String? ?? '';
    final isYoutube = source == 'youtube';
    final cover = song['cover'] as String?;
    final thumbnail = song['thumbnail'] as String?;
    final preview = song['preview'] as String?;
    final duration = song['duration'] as int?;
    final lyrics = song['lyrics'] as String?;
    final videoId = song['videoId'] as String?;

    return GestureDetector(
      onTap: () => isYoutube ? _selectYoutubeSong(song) : _selectSong(song),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isYoutube
                ? AppColors.error.withValues(alpha: 0.3)
                : (isDark ? AppColors.darkBorderLight : AppColors.lightBorderLight),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isYoutube ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    image: thumbnail != null || cover != null
                        ? DecorationImage(image: NetworkImage(thumbnail ?? cover!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: thumbnail == null && cover == null
                      ? Icon(isYoutube ? Icons.play_circle_fill_rounded : Icons.music_note_rounded,
                          color: isYoutube ? AppColors.error : AppColors.primary, size: 22)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : AppColors.lightText)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(artist, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isYoutube ? AppColors.error.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(isYoutube ? 'YouTube' : 'Deezer',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isYoutube ? AppColors.error : AppColors.primary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (duration != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg : AppColors.neutral50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${(duration / 60).floor()}:${(duration % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  ),
                const SizedBox(width: 4),
                Icon(isYoutube ? Icons.add_circle_outline_rounded : Icons.add_circle_rounded,
                    color: isYoutube ? AppColors.error : AppColors.primary, size: 28),
              ],
            ),
            if (isYoutube && videoId != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse('https://www.youtube.com/watch?v=$videoId')),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_fill_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 6),
                      Text('Abrir no YouTube', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error)),
                    ],
                  ),
                ),
              ),
            ],
            if (lyrics != null && lyrics.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : AppColors.neutral50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  lyrics.length > 150 ? '${lyrics.substring(0, 150)}...' : lyrics,
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectYoutubeSong(Map<String, dynamic> song) async {
    try {
      await _worshipApi.createSong({
        'title': song['title'] as String? ?? '',
        'artist': song['artist'] as String? ?? '',
        'youtubeUrl': song['link'] as String? ?? '',
        'thumbnail': song['thumbnail'] as String?,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Música salva no repertório!', style: TextStyle(fontSize: 14))),
            ]),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            duration: const Duration(seconds: 3),
          ),
        );
        ref.invalidate(songsProvider);
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}
