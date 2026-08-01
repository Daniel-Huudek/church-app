import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../data/worship_api.dart';
import '../../domain/worship_models.dart';
import '../widgets/chord_viewer.dart';
import 'song_bpm_picker_screen.dart';

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
  int _contentTab = 1;
  double _editorFontSize = 16;

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
          const Icon(Icons.error_outline_rounded,
              color: Colors.white, size: 20),
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
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF6F4EF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Fechar',
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : const Color(0xFF1A2B48),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Editar Música',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A2B48),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Salvar',
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF008CFF),
                    size: 28,
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIdentityFields(isDark),
                  const SizedBox(height: 20),
                  _buildMetadataStrip(isDark),
                  const SizedBox(height: 20),
                  _buildContentSwitcher(isDark),
                  const SizedBox(height: 12),
                  _buildEditor(isDark),
                  const SizedBox(height: 20),
                  _buildCollapsibleField(
                    isDark: isDark,
                    title: 'YouTube e links',
                    icon: Icons.link_rounded,
                    controller: _youtubeCtrl,
                    hint: 'Cole o link do YouTube',
                  ),
                  const SizedBox(height: 10),
                  _buildCollapsibleField(
                    isDark: isDark,
                    title: 'Observações',
                    icon: Icons.edit_note_rounded,
                    controller: _notesCtrl,
                    hint: 'Informações adicionais',
                    multiline: true,
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              top: false,
              child: Container(
                color: bg,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: _buildSaveButton(),
              ),
            ),
    );
  }

  Widget _buildIdentityFields(bool isDark) {
    final primary = isDark ? Colors.white : const Color(0xFF1A2B48);
    final secondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final line = isDark ? const Color(0xFF2D2D44) : const Color(0xFFD9D7D0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _titleCtrl,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: primary,
          ),
          decoration: InputDecoration(
            hintText: 'Nome da música',
            hintStyle: TextStyle(color: secondary),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: line),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: line),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF008CFF), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _artistCtrl,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: secondary,
          ),
          decoration: InputDecoration(
            hintText: 'Artista',
            hintStyle: TextStyle(color: secondary),
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: Color(0xFF008CFF),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataStrip(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _metadataChip(
            isDark: isDark,
            icon: Icons.music_note_rounded,
            label: 'Tom',
            value: _keyCtrl.text.trim().isEmpty ? '—' : _keyCtrl.text.trim(),
            onTap: () => _editMetadata(
              title: 'Tom',
              controller: _keyCtrl,
              hint: 'Ex.: G, Bb, F#m',
            ),
          ),
          const SizedBox(width: 8),
          _metadataChip(
            isDark: isDark,
            icon: Icons.speed_rounded,
            label: 'BPM',
            value: _bpmCtrl.text.trim().isEmpty ? '—' : _bpmCtrl.text.trim(),
            onTap: _openBpmPicker,
          ),
          const SizedBox(width: 8),
          _metadataChip(
            isDark: isDark,
            icon: Icons.straighten_rounded,
            label: 'Capo',
            value: _capoCtrl.text.trim().isEmpty ? '—' : _capoCtrl.text.trim(),
            onTap: () => _editMetadata(
              title: 'Capo',
              controller: _capoCtrl,
              hint: 'Ex.: 2',
              numeric: true,
            ),
          ),
          const SizedBox(width: 8),
          _metadataChip(
            isDark: isDark,
            icon: Icons.timer_outlined,
            label: 'Duração',
            value: _durationLabel,
            onTap: () => _editMetadata(
              title: 'Duração em segundos',
              controller: _durationCtrl,
              hint: 'Ex.: 272',
              numeric: true,
            ),
          ),
        ],
      ),
    );
  }

  String get _durationLabel {
    final seconds = int.tryParse(_durationCtrl.text.trim());
    if (seconds == null || seconds <= 0) return '—';
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  Future<void> _openBpmPicker() async {
    final current = int.tryParse(_bpmCtrl.text.trim()) ?? 72;
    final selected = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SongBpmPickerScreen(initialBpm: current),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _bpmCtrl.text = selected.toString());
  }

  Widget _metadataChip({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161622) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFD9D7D0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF008CFF)),
            const SizedBox(width: 6),
            Text(
              '$label ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A2B48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMetadata({
    required String title,
    required TextEditingController controller,
    required String hint,
    bool numeric = false,
  }) async {
    final draft = TextEditingController(text: controller.text);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title),
        content: TextField(
          controller: draft,
          autofocus: true,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (text) => Navigator.pop(ctx, text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, draft.text),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    draft.dispose();
    if (value == null || !mounted) return;
    setState(() => controller.text = value.trim());
  }

  Widget _buildContentSwitcher(bool isDark) {
    final inactive = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : const Color(0xFFEAE8E2),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          _contentTabButton(
            label: 'Letra',
            icon: Icons.text_fields_rounded,
            index: 0,
            inactive: inactive,
          ),
          _contentTabButton(
            label: 'Cifra',
            icon: Icons.piano_rounded,
            index: 1,
            inactive: inactive,
          ),
        ],
      ),
    );
  }

  Widget _contentTabButton({
    required String label,
    required IconData icon,
    required int index,
    required Color inactive,
  }) {
    final selected = _contentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _contentTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? const Color(0xFF008CFF) : inactive,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? const Color(0xFF008CFF) : inactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(bool isDark) {
    final controller = _contentTab == 0 ? _lyricsCtrl : _chordsCtrl;
    final isChords = _contentTab == 1;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : const Color(0xFFFFFEFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFD9D7D0),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
            child: Row(
              children: [
                Text(
                  isChords ? 'EDITOR DE CIFRA' : 'EDITOR DE LETRA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF7A7F8A),
                  ),
                ),
                const Spacer(),
                _editorIconButton(
                  tooltip: 'Diminuir fonte',
                  icon: Icons.text_decrease_rounded,
                  onPressed: () => setState(
                    () => _editorFontSize = (_editorFontSize - 1).clamp(12, 26),
                  ),
                ),
                _editorIconButton(
                  tooltip: 'Aumentar fonte',
                  icon: Icons.text_increase_rounded,
                  onPressed: () => setState(
                    () => _editorFontSize = (_editorFontSize + 1).clamp(12, 26),
                  ),
                ),
                _editorIconButton(
                  tooltip: 'Visualizar',
                  icon: Icons.fullscreen_rounded,
                  onPressed: () => _showPreview(isDark),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE8E6E0),
          ),
          TextField(
            key: ValueKey(_contentTab),
            controller: controller,
            minLines: 14,
            maxLines: 22,
            keyboardType: TextInputType.multiline,
            style: TextStyle(
              fontFamily: isChords ? 'monospace' : null,
              fontSize: _editorFontSize,
              height: 1.55,
              fontWeight: isChords ? FontWeight.w600 : FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF1A2B48),
            ),
            decoration: InputDecoration(
              hintText: isChords
                  ? 'Digite ou cole a cifra aqui...'
                  : 'Digite ou cole a letra aqui...',
              hintStyle: TextStyle(
                color:
                    isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorIconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: const Color(0xFF008CFF)),
    );
  }

  Future<void> _showPreview(bool isDark) {
    final isChords = _contentTab == 1;
    final content = isChords ? _chordsCtrl.text : _lyricsCtrl.text;
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor:
            isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
            title: Text(isChords ? 'Prévia da cifra' : 'Prévia da letra'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: content.trim().isEmpty
                ? const Center(child: Text('Nenhum conteúdo para visualizar'))
                : isChords
                    ? ChordViewer(
                        chords: content,
                        textStyle: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: _editorFontSize,
                          height: 1.6,
                          color: isDark
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF1A2B48),
                        ),
                      )
                    : SelectableText(
                        content,
                        style: TextStyle(
                          fontSize: _editorFontSize,
                          height: 1.6,
                          color: isDark
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF1A2B48),
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleField({
    required bool isDark,
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    bool multiline = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFD9D7D0),
        ),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(icon, color: const Color(0xFF008CFF), size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A2B48),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: [
          TextField(
            controller: controller,
            minLines: multiline ? 3 : 1,
            maxLines: multiline ? 5 : 1,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF008CFF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Salvar alterações',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
