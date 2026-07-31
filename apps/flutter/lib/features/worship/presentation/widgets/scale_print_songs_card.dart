import 'package:flutter/material.dart';

import 'scale_print_card.dart';

/// Música exibida no card de repertório para print.
class ScalePrintSongItem {
  final String title;
  final String? artist;
  final String? key;

  const ScalePrintSongItem({
    required this.title,
    this.artist,
    this.key,
  });
}

/// Card de músicas da escala — mesmo visual do card de print (mockup B).
class ScalePrintSongsCard extends StatelessWidget {
  final List<ScalePrintSongItem> songs;
  final double maxWidth;

  const ScalePrintSongsCard({
    super.key,
    required this.songs,
    this.maxWidth = 360,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: ScalePrintCardData.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ScalePrintCardData.border, width: 1.4),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'MÚSICAS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
              color: ScalePrintCardData.labelGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            songs.isEmpty ? 'Nenhuma música' : '${songs.length} na escala',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: ScalePrintCardData.navy,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: ScalePrintCardData.divider),
          if (songs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Nenhuma música selecionada.',
                style: TextStyle(
                  fontSize: 14,
                  color: ScalePrintCardData.labelGray,
                ),
              ),
            )
          else
            ...List.generate(songs.length, (i) {
              final song = songs[i];
              final meta = <String>[
                if (song.artist != null && song.artist!.trim().isNotEmpty)
                  song.artist!.trim(),
                if (song.key != null && song.key!.trim().isNotEmpty)
                  'Tom ${song.key!.trim()}',
              ].join(' · ');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ScalePrintCardData.labelGray,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  color: ScalePrintCardData.navy,
                                ),
                              ),
                              if (meta.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  meta,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: ScalePrintCardData.labelGray,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < songs.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: ScalePrintCardData.divider,
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}
