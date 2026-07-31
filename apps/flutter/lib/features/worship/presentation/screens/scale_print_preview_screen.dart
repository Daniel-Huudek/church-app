import 'package:flutter/material.dart';

import '../widgets/scale_print_card.dart';
import '../widgets/scale_print_songs_card.dart';

/// Tela fullscreen limpa com o card da escala — ideal para tirar print.
class ScalePrintPreviewScreen extends StatelessWidget {
  final ScalePrintCardData data;
  final List<ScalePrintSongItem> songs;
  final bool popToRootOnDone;

  const ScalePrintPreviewScreen({
    super.key,
    required this.data,
    this.songs = const [],
    this.popToRootOnDone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Card para print',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'Tire um print desta tela para compartilhar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScalePrintCard(data: data),
                      const SizedBox(height: 16),
                      ScalePrintSongsCard(songs: songs),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (popToRootOnDone) {
                      Navigator.of(context).pop(true);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008CFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Concluir',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre a preview do card (fullscreen).
Future<T?> openScalePrintPreview<T>({
  required BuildContext context,
  required ScalePrintCardData data,
  List<ScalePrintSongItem> songs = const [],
  bool popToRootOnDone = false,
}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ScalePrintPreviewScreen(
        data: data,
        songs: songs,
        popToRootOnDone: popToRootOnDone,
      ),
    ),
  );
}
