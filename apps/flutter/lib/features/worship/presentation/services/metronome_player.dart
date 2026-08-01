import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Metrônomo reutilizável com clique sintetizado no próprio app.
class MetronomePlayer {
  AudioPool? _regularClickPool;
  AudioPool? _accentClickPool;
  Future<void>? _prepareFuture;
  Timer? _timer;
  int _beatIndex = 0;
  int _generation = 0;
  bool _disposed = false;
  bool _running = false;
  bool _muted = false;

  Future<void> prepare() {
    return _prepareFuture ??= _prepare();
  }

  void setMuted(bool muted) {
    _muted = muted;
  }

  Future<void> _prepare() async {
    try {
      final pools = await Future.wait([
        AudioPool.create(
          source: BytesSource(
            _buildClickSound(frequency: 1150),
            mimeType: 'audio/wav',
          ),
          minPlayers: 1,
          maxPlayers: 2,
          playerMode: PlayerMode.lowLatency,
        ),
        AudioPool.create(
          source: BytesSource(
            _buildClickSound(frequency: 1750),
            mimeType: 'audio/wav',
          ),
          minPlayers: 1,
          maxPlayers: 2,
          playerMode: PlayerMode.lowLatency,
        ),
      ]);
      if (_disposed) {
        await Future.wait(pools.map((pool) => pool.dispose()));
        return;
      }
      _regularClickPool = pools[0];
      _accentClickPool = pools[1];
    } catch (_) {
      // O indicador visual ainda funciona em plataformas sem áudio.
    }
  }

  void start({
    required int bpm,
    int beatsPerMeasure = 4,
    void Function(int beat)? onBeat,
  }) {
    stop();
    if (_disposed || bpm <= 0 || beatsPerMeasure <= 0) return;

    final safeBpm = bpm.clamp(30, 300);
    final beatDuration = Duration(
      microseconds: (60000000 / safeBpm).round(),
    );
    _beatIndex = 0;
    _running = true;
    final generation = ++_generation;
    unawaited(
      _playBeat(
        generation: generation,
        beatsPerMeasure: beatsPerMeasure,
        onBeat: onBeat,
      ),
    );
    _timer = Timer.periodic(beatDuration, (_) {
      unawaited(
        _playBeat(
          generation: generation,
          beatsPerMeasure: beatsPerMeasure,
          onBeat: onBeat,
        ),
      );
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _beatIndex = 0;
    _running = false;
    _generation++;
  }

  Future<void> _playBeat({
    required int generation,
    required int beatsPerMeasure,
    void Function(int beat)? onBeat,
  }) async {
    if (_disposed || !_running || generation != _generation) return;

    final currentBeat = _beatIndex % beatsPerMeasure;
    _beatIndex++;
    onBeat?.call(currentBeat);

    if (_muted) return;
    await prepare();
    if (_disposed || !_running || _muted || generation != _generation) return;
    final pool = currentBeat == 0 ? _accentClickPool : _regularClickPool;
    if (pool == null) return;

    try {
      final stop = await pool.start(volume: currentBeat == 0 ? 0.9 : 0.68);
      Timer(const Duration(milliseconds: 80), () {
        unawaited(stop().catchError((_) {}));
      });
    } catch (_) {
      // Uma falha pontual de áudio não interrompe o metrônomo.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    stop();
    await Future.wait([
      if (_regularClickPool != null) _regularClickPool!.dispose(),
      if (_accentClickPool != null) _accentClickPool!.dispose(),
    ]);
  }

  Uint8List _buildClickSound({
    required double frequency,
    int durationMs = 55,
  }) {
    const sampleRate = 22050;
    const bytesPerSample = 2;
    final sampleCount = sampleRate * durationMs ~/ 1000;
    final dataSize = sampleCount * bytesPerSample;
    final wav = ByteData(44 + dataSize);

    void writeText(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        wav.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeText(0, 'RIFF');
    wav.setUint32(4, 36 + dataSize, Endian.little);
    writeText(8, 'WAVE');
    writeText(12, 'fmt ');
    wav.setUint32(16, 16, Endian.little);
    wav.setUint16(20, 1, Endian.little);
    wav.setUint16(22, 1, Endian.little);
    wav.setUint32(24, sampleRate, Endian.little);
    wav.setUint32(28, sampleRate * bytesPerSample, Endian.little);
    wav.setUint16(32, bytesPerSample, Endian.little);
    wav.setUint16(34, 16, Endian.little);
    writeText(36, 'data');
    wav.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < sampleCount; i++) {
      final time = i / sampleRate;
      final attack = math.min(1.0, i / 24);
      final envelope = math.exp(-time * 62) * attack;
      final wave = math.sin(2 * math.pi * frequency * time);
      final sample = (wave * envelope * 0.78 * 32767).round();
      wav.setInt16(44 + i * bytesPerSample, sample, Endian.little);
    }
    return wav.buffer.asUint8List();
  }
}
