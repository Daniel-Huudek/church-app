import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/metronome_player.dart';

/// Seletor visual de BPM com preview sonoro da batida.
class SongBpmPickerScreen extends StatefulWidget {
  final int initialBpm;

  const SongBpmPickerScreen({
    super.key,
    required this.initialBpm,
  });

  @override
  State<SongBpmPickerScreen> createState() => _SongBpmPickerScreenState();
}

class _SongBpmPickerScreenState extends State<SongBpmPickerScreen> {
  static const _minBpm = 30;
  static const _maxBpm = 300;

  final _metronome = MetronomePlayer();
  late final FixedExtentScrollController _wheelController;
  Timer? _restartTimer;
  late int _selectedBpm;
  int _beatsPerMeasure = 4;
  int _activeBeat = -1;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _selectedBpm = widget.initialBpm.clamp(_minBpm, _maxBpm);
    _wheelController = FixedExtentScrollController(
      initialItem: _selectedBpm - _minBpm,
    );
    _metronome.prepare();
  }

  @override
  void dispose() {
    _restartTimer?.cancel();
    unawaited(_metronome.dispose());
    _wheelController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_playing) {
      _stopPreview();
    } else {
      setState(() => _playing = true);
      _startPreview();
    }
  }

  void _startPreview() {
    _metronome.start(
      bpm: _selectedBpm,
      beatsPerMeasure: _beatsPerMeasure,
      onBeat: (beat) {
        if (mounted && _playing) setState(() => _activeBeat = beat);
      },
    );
  }

  void _stopPreview() {
    _restartTimer?.cancel();
    _metronome.stop();
    if (mounted) {
      setState(() {
        _playing = false;
        _activeBeat = -1;
      });
    }
  }

  void _schedulePreviewRestart() {
    if (!_playing) return;
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 180), _startPreview);
  }

  void _selectBpm(int bpm) {
    final next = bpm.clamp(_minBpm, _maxBpm);
    if (next == _selectedBpm) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedBpm = next);
    _schedulePreviewRestart();
  }

  void _changeBpm(int delta) {
    final next = (_selectedBpm + delta).clamp(_minBpm, _maxBpm);
    _wheelController.animateToItem(
      next - _minBpm,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _changeMeasure(int beats) {
    if (beats == _beatsPerMeasure) return;
    setState(() {
      _beatsPerMeasure = beats;
      _activeBeat = -1;
    });
    _schedulePreviewRestart();
  }

  String get _tempoLabel {
    if (_selectedBpm < 60) return 'Lento';
    if (_selectedBpm < 90) return 'Moderado';
    if (_selectedBpm < 120) return 'Andante';
    if (_selectedBpm < 160) return 'Rápido';
    return 'Muito rápido';
  }

  void _apply() {
    _stopPreview();
    Navigator.pop(context, _selectedBpm);
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF090C11);
    const panel = Color(0xFF11161D);
    const accent = Color(0xFF008CFF);
    const muted = Color(0xFF7C8798);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Fechar',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
        title: const Text(
          'Selecionar BPM',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _apply,
            child: const Text(
              'Aplicar',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            children: [
              const Text(
                'COMPASSO',
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [2, 3, 4].map((beats) {
                  final selected = beats == _beatsPerMeasure;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: GestureDetector(
                      onTap: () => _changeMeasure(beats),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? accent : panel,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? accent : const Color(0xFF252D38),
                          ),
                        ),
                        child: Text(
                          '$beats',
                          style: TextStyle(
                            color: selected ? Colors.white : muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_beatsPerMeasure, (index) {
                  final active = _playing && _activeBeat == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: active ? 34 : 30,
                    height: active ? 34 : 30,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? accent : panel,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? accent : const Color(0xFF252D38),
                      ),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: active ? Colors.white : muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ListWheelScrollView.useDelegate(
                      controller: _wheelController,
                      itemExtent: 90,
                      diameterRatio: 1.55,
                      perspective: 0.003,
                      overAndUnderCenterOpacity: 0.22,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        _selectBpm(_minBpm + index);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _maxBpm - _minBpm + 1,
                        builder: (context, index) {
                          final bpm = _minBpm + index;
                          final selected = bpm == _selectedBpm;
                          return Center(
                            child: Text(
                              '$bpm',
                              style: TextStyle(
                                color: selected ? Colors.white : muted,
                                fontSize: selected ? 76 : 52,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    IgnorePointer(
                      child: Container(
                        height: 92,
                        decoration: const BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: accent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$_selectedBpm BPM · $_tempoLabel',
                style: const TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _roundControl(
                    icon: Icons.remove_rounded,
                    onTap: () => _changeBpm(-1),
                    panel: panel,
                    muted: muted,
                  ),
                  const SizedBox(width: 22),
                  GestureDetector(
                    onTap: _togglePlay,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  _roundControl(
                    icon: Icons.add_rounded,
                    onTap: () => _changeBpm(1),
                    panel: panel,
                    muted: muted,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Aplicar $_selectedBpm BPM',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundControl({
    required IconData icon,
    required VoidCallback onTap,
    required Color panel,
    required Color muted,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: panel,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF252D38)),
        ),
        child: Icon(icon, color: muted, size: 26),
      ),
    );
  }
}
