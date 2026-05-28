import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/worship_api.dart';

class CreateRepertorioScreen extends ConsumerStatefulWidget {
  const CreateRepertorioScreen({super.key});

  @override
  ConsumerState<CreateRepertorioScreen> createState() => _CreateRepertorioScreenState();
}

class _CreateRepertorioScreenState extends ConsumerState<CreateRepertorioScreen>
    with SingleTickerProviderStateMixin {
  late final WorshipApi _worshipApi;
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _bpmCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _capoCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _lyricsCtrl = TextEditingController();
  final _chordsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  bool _saving = false;
  bool _fetching = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _worshipApi = WorshipApi(ref.read(apiClientProvider));
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  Future<void> _fetchFromWeb() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      _showError('Informe a URL da música');
      return;
    }
    setState(() => _fetching = true);
    try {
      final data = await _worshipApi.fetchSong(url);
      _titleCtrl.text = data['title'] as String? ?? '';
      _artistCtrl.text = data['artist'] as String? ?? '';
      _keyCtrl.text = data['key'] as String? ?? '';
      _lyricsCtrl.text = data['lyrics'] as String? ?? '';
      _chordsCtrl.text = data['chords'] as String? ?? '';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Expanded(child: Text('Música encontrada! Campos preenchidos.', style: TextStyle(fontSize: 14))),
            ]),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showError('Erro ao buscar: $e');
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showError('Informe o nome da versão');
      return;
    }
    setState(() => _saving = true);
    try {
      await _worshipApi.createSong({
        'title': _titleCtrl.text.trim(),
        if (_artistCtrl.text.trim().isNotEmpty) 'artist': _artistCtrl.text.trim(),
        if (_keyCtrl.text.trim().isNotEmpty) 'key': _keyCtrl.text.trim(),
        if (_bpmCtrl.text.trim().isNotEmpty) 'bpm': int.tryParse(_bpmCtrl.text.trim()),
        if (_durationCtrl.text.trim().isNotEmpty) 'duration': int.tryParse(_durationCtrl.text.trim()),
        if (_capoCtrl.text.trim().isNotEmpty) 'capo': int.tryParse(_capoCtrl.text.trim()),
        if (_youtubeCtrl.text.trim().isNotEmpty) 'youtubeUrl': _youtubeCtrl.text.trim(),
        if (_lyricsCtrl.text.trim().isNotEmpty) 'lyrics': _lyricsCtrl.text.trim(),
        if (_chordsCtrl.text.trim().isNotEmpty) 'chords': _chordsCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
      if (mounted) context.pop();
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
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
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
    _animCtrl.dispose();
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
          'Nova Música',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.lightText,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildFetchSection(isDark),
              const SizedBox(height: 20),
              _buildSection('Informações', Icons.music_note_rounded, [
                _input(_titleCtrl, 'Nome da Versão', icon: Icons.music_note_outlined),
                const SizedBox(height: 14),
                _input(_artistCtrl, 'Artista', icon: Icons.person_outline_rounded),
              ]),
              const SizedBox(height: 20),
              _buildSection('Detalhes Musicais', Icons.tune_rounded, [
                Row(
                  children: [
                    Expanded(child: _input(_keyCtrl, 'Tom', icon: Icons.music_note_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _input(_bpmCtrl, 'BPM', icon: Icons.speed_rounded, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _input(_capoCtrl, 'Capo', icon: Icons.straighten_rounded, keyboardType: TextInputType.number)),
                  ],
                ),
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
      ),
    );
  }

  Widget _buildFetchSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.language_rounded, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Text(
                'Importar da Web',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
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
                    controller: _urlCtrl,
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.lightText),
                    decoration: InputDecoration(
                      hintText: 'https://cifraclub.com/...',
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
                  onPressed: _fetching ? null : _fetchFromWeb,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: _fetching
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
          const SizedBox(height: 8),
          Text(
            'Cole o link do CifraClub ou Letras.mus.br',
            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.library_music_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          const Text(
            'Adicionar Música',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Preencha os detalhes para cadastrar uma nova música no repertório',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorderLight : AppColors.lightBorderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.lightText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String label, {IconData? icon, bool multiline = false, TextInputType? keyboardType}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: multiline ? 4 : 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorderLight : AppColors.lightBorder,
        ),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: multiline ? 5 : 1,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.lightText,
        ),
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.primary) : null,
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          floatingLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.only(top: multiline ? 12 : 16, bottom: multiline ? 12 : 16, left: icon != null ? 4 : 0),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.pressed) ? 0 : 4),
          shadowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: _saving
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Salvar Música', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}
