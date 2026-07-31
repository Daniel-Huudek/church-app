import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../data/worship_api.dart';
import '../../domain/worship_models.dart';

class EditSongScreen extends ConsumerStatefulWidget {
  final String songId;
  const EditSongScreen({super.key, required this.songId});

  @override
  ConsumerState<EditSongScreen> createState() => _EditSongScreenState();
}

class _EditSongScreenState extends ConsumerState<EditSongScreen> {
  late final WorshipApi _worshipApi;
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _bpmCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _capoCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _lyricsCtrl = TextEditingController();
  final _chordsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _worshipApi = WorshipApi(ref.read(apiClientProvider));
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _worshipApi.getSong(widget.songId);
      final song = Song.fromJson(data);
      _titleCtrl.text = song.title;
      _artistCtrl.text = song.artist ?? '';
      _keyCtrl.text = song.key ?? '';
      _bpmCtrl.text = song.bpm?.toString() ?? '';
      _durationCtrl.text = song.duration?.toString() ?? '';
      _capoCtrl.text = song.capo?.toString() ?? '';
      _youtubeCtrl.text = song.youtubeUrl ?? '';
      _lyricsCtrl.text = song.lyrics ?? '';
      _chordsCtrl.text = song.chords ?? '';
      _notesCtrl.text = song.notes ?? '';
      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showError('Informe o nome da versão');
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'artist': _artistCtrl.text.trim(),
        'key': _keyCtrl.text.trim(),
        'youtubeUrl': _youtubeCtrl.text.trim(),
        'lyrics': _lyricsCtrl.text,
        'chords': _chordsCtrl.text,
        'notes': _notesCtrl.text.trim(),
      };
      final bpm = int.tryParse(_bpmCtrl.text.trim());
      final duration = int.tryParse(_durationCtrl.text.trim());
      final capo = int.tryParse(_capoCtrl.text.trim());
      if (bpm != null) payload['bpm'] = bpm;
      if (duration != null) payload['duration'] = duration;
      if (capo != null) payload['capo'] = capo;

      await _worshipApi.updateSong(widget.songId, payload);
      if (mounted) context.pop(true);
    } catch (e) {
      _showError('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 14))),
        ]),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _keyCtrl.dispose();
    _bpmCtrl.dispose();
    _durationCtrl.dispose();
    _capoCtrl.dispose();
    _youtubeCtrl.dispose();
    _lyricsCtrl.dispose();
    _chordsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF008CFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF008CFF), size: 24),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Editar Música',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSection('Informações', Icons.music_note_rounded, [
                    _input(_titleCtrl, 'Nome da Versão', icon: Icons.music_note_outlined),
                    const SizedBox(height: 14),
                    _input(_artistCtrl, 'Artista', icon: Icons.person_outline_rounded),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Detalhes Musicais', Icons.tune_rounded, [
                    Row(children: [
                      Expanded(child: _input(_keyCtrl, 'Tom', icon: Icons.music_note_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _input(_bpmCtrl, 'BPM', icon: Icons.speed_rounded, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _input(_capoCtrl, 'Capo', icon: Icons.straighten_rounded, keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 14),
                    _input(_durationCtrl, 'Duração (seg)', icon: Icons.timer_outlined, keyboardType: TextInputType.number),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Links', Icons.link_rounded, [
                    _input(_youtubeCtrl, 'YouTube', icon: Icons.videocam_outlined),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Conteúdo', Icons.article_outlined, [
                    _input(_lyricsCtrl, 'Letra', icon: Icons.text_fields_rounded, multiline: true),
                    const SizedBox(height: 14),
                    _input(_chordsCtrl, 'Cifra', icon: Icons.piano_rounded, multiline: true),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Extras', Icons.more_horiz_rounded, [
                    _input(_notesCtrl, 'Observações', icon: Icons.edit_note_rounded, multiline: true),
                  ]),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF008CFF), Color(0xFF0066CC)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF008CFF).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 16),
        const Text('Editar Música', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text('Altere os dados da música', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), height: 1.4)),
      ]),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFF3F4F6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFF008CFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: const Color(0xFF008CFF)),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _input(TextEditingController ctrl, String label, {IconData? icon, bool multiline = false, TextInputType? keyboardType}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: multiline ? 4 : 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: multiline ? 5 : 1,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF111827)),
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF008CFF)) : null,
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF6B7280)),
          floatingLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF008CFF)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.only(top: multiline ? 12 : 16, bottom: multiline ? 12 : 16, left: icon != null ? 4 : 0),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF008CFF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.pressed) ? 0 : 4),
          shadowColor: WidgetStateProperty.all(const Color(0xFF008CFF).withValues(alpha: 0.3)),
        ),
        child: _saving
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_rounded, size: 20),
                SizedBox(width: 8),
                Text('Salvar Alterações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
      ),
    );
  }
}
