import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../providers/website_provider.dart';

class WebsiteContentScreen extends ConsumerStatefulWidget {
  const WebsiteContentScreen({super.key});

  @override
  ConsumerState<WebsiteContentScreen> createState() => _WebsiteContentScreenState();
}

class _WebsiteContentScreenState extends ConsumerState<WebsiteContentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
  bool _saving = false;
  String? _uploadingKind;

  late final TextEditingController _brand;
  late final TextEditingController _fullName;
  late final TextEditingController _about;
  late final TextEditingController _addressLine;
  late final TextEditingController _email;
  late final TextEditingController _facebook;
  late final TextEditingController _instagram;
  late final TextEditingController _youtube;
  late final TextEditingController _seriesTitle;
  late final TextEditingController _seriesSubtitle;
  late final TextEditingController _seriesCaption;
  late final TextEditingController _seriesImage;
  late final TextEditingController _weeklyText;
  late final TextEditingController _weeklyRef;
  late final TextEditingController _leaderName;
  late final TextEditingController _leaderRole;
  late final TextEditingController _leaderImage;
  late final TextEditingController _leaderBio;
  late final TextEditingController _faithParagraphs;

  final List<_EventDraft> _events = [];

  @override
  void initState() {
    super.initState();
    _brand = TextEditingController();
    _fullName = TextEditingController();
    _about = TextEditingController();
    _addressLine = TextEditingController();
    _email = TextEditingController();
    _facebook = TextEditingController();
    _instagram = TextEditingController();
    _youtube = TextEditingController();
    _seriesTitle = TextEditingController();
    _seriesSubtitle = TextEditingController();
    _seriesCaption = TextEditingController();
    _seriesImage = TextEditingController();
    _weeklyText = TextEditingController();
    _weeklyRef = TextEditingController();
    _leaderName = TextEditingController();
    _leaderRole = TextEditingController();
    _leaderImage = TextEditingController();
    _leaderBio = TextEditingController();
    _faithParagraphs = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in [
      _brand, _fullName, _about, _addressLine, _email, _facebook, _instagram, _youtube,
      _seriesTitle, _seriesSubtitle, _seriesCaption, _seriesImage, _weeklyText, _weeklyRef,
      _leaderName, _leaderRole, _leaderImage, _leaderBio, _faithParagraphs,
    ]) {
      c.dispose();
    }
    for (final e in _events) {
      e.dispose();
    }
    super.dispose();
  }

  void _hydrate(Map<String, dynamic> content) {
    if (_initialized || content.isEmpty) return;

    _brand.text = '${content['brand'] ?? ''}';
    _fullName.text = '${content['fullName'] ?? ''}';
    _about.text = '${content['about'] ?? ''}';

    final address = Map<String, dynamic>.from((content['address'] as Map?) ?? {});
    _addressLine.text = '${address['line'] ?? ''}';
    _email.text = '${address['email'] ?? ''}';

    final social = (content['social'] as List?) ?? [];
    for (final item in social) {
      final map = Map<String, dynamic>.from(item as Map);
      final icon = '${map['icon']}';
      final href = '${map['href'] ?? ''}';
      if (icon == 'facebook') _facebook.text = href;
      if (icon == 'instagram') _instagram.text = href;
      if (icon == 'youtube') _youtube.text = href;
    }

    final series = Map<String, dynamic>.from((content['series'] as Map?) ?? {});
    _seriesTitle.text = '${series['title'] ?? ''}';
    _seriesSubtitle.text = '${series['subtitle'] ?? ''}';
    _seriesCaption.text = '${series['caption'] ?? ''}';
    _seriesImage.text = '${series['image'] ?? ''}';

    final weekly = Map<String, dynamic>.from((content['weeklyWord'] as Map?) ?? {});
    _weeklyText.text = '${weekly['text'] ?? ''}';
    _weeklyRef.text = '${weekly['reference'] ?? ''}';

    final leadership = Map<String, dynamic>.from((content['leadership'] as Map?) ?? {});
    _leaderName.text = '${leadership['name'] ?? ''}';
    _leaderRole.text = '${leadership['role'] ?? ''}';
    _leaderImage.text = '${leadership['image'] ?? ''}';
    _leaderBio.text = '${leadership['bio'] ?? ''}';

    final faith = Map<String, dynamic>.from((content['faith'] as Map?) ?? {});
    final paragraphs = (faith['paragraphs'] as List?)?.map((e) => '$e').toList() ?? [];
    _faithParagraphs.text = paragraphs.join('\n\n');

    for (final e in _events) {
      e.dispose();
    }
    _events.clear();
    final events = (content['events'] as List?) ?? [];
    for (final item in events) {
      final map = Map<String, dynamic>.from(item as Map);
      _events.add(_EventDraft(
        title: '${map['title'] ?? ''}',
        date: '${map['date'] ?? ''}',
        time: '${map['time'] ?? ''}',
      ));
    }
    if (_events.isEmpty) {
      _events.add(_EventDraft());
    }

    _initialized = true;
  }

  Map<String, dynamic> _buildPayload(Map<String, dynamic> current) {
    final address = Map<String, dynamic>.from((current['address'] as Map?) ?? {});
    final email = _email.text.trim();
    address['line'] = _addressLine.text.trim();
    address['email'] = email;
    address['emailHref'] = 'mailto:$email';
    if ((address['mapUrl'] as String?)?.isEmpty ?? true) {
      address['mapUrl'] =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_addressLine.text.trim())}';
    }
    if ((address['mapEmbed'] as String?)?.isEmpty ?? true) {
      address['mapEmbed'] =
          'https://maps.google.com/maps?q=${Uri.encodeComponent(_addressLine.text.trim())}&output=embed';
    }

    final leadership = Map<String, dynamic>.from((current['leadership'] as Map?) ?? {});
    leadership['name'] = _leaderName.text.trim();
    leadership['role'] = _leaderRole.text.trim();
    leadership['image'] = _leaderImage.text.trim().isEmpty ? '/pastor.png' : _leaderImage.text.trim();
    leadership['bio'] = _leaderBio.text.trim();
    leadership['titlePrefix'] = leadership['titlePrefix'] ?? 'Nossa';
    leadership['titleAccent'] = leadership['titleAccent'] ?? 'Liderança';

    final faith = Map<String, dynamic>.from((current['faith'] as Map?) ?? {});
    faith['titlePrefix'] = faith['titlePrefix'] ?? 'Afirmação de Fé da';
    faith['titleAccent'] = faith['titleAccent'] ?? 'IPI do Brasil';
    faith['paragraphs'] = _faithParagraphs.text
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return {
      ...current,
      'brand': _brand.text.trim(),
      'logoLabel': current['logoLabel'] ?? 'PRIMEIRA IPI AVARÉ',
      'fullName': _fullName.text.trim(),
      'about': _about.text.trim(),
      'address': address,
      'social': [
        {'label': 'Facebook', 'href': _facebook.text.trim().isEmpty ? '#' : _facebook.text.trim(), 'icon': 'facebook'},
        {'label': 'Instagram', 'href': _instagram.text.trim().isEmpty ? '#' : _instagram.text.trim(), 'icon': 'instagram'},
        {'label': 'YouTube', 'href': _youtube.text.trim().isEmpty ? '#' : _youtube.text.trim(), 'icon': 'youtube'},
      ],
      'series': {
        'title': _seriesTitle.text.trim(),
        'subtitle': _seriesSubtitle.text.trim(),
        'caption': _seriesCaption.text.trim(),
        'image': _seriesImage.text.trim(),
      },
      'weeklyWord': {
        'text': _weeklyText.text.trim(),
        'reference': _weeklyRef.text.trim(),
      },
      'events': _events
          .map((e) => {
                'title': e.title.text.trim(),
                'date': e.date.text.trim(),
                'time': e.time.text.trim(),
              })
          .where((e) => (e['title'] as String).isNotEmpty)
          .toList(),
      'leadership': leadership,
      'faith': faith,
      'nav': current['nav'] ?? [],
      'news': current['news'] ?? [],
      'streams': current['streams'] ?? [],
      'usefulLinks': current['usefulLinks'] ?? [],
    };
  }

  Future<void> _save(Map<String, dynamic> current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await ref.read(websiteContentProvider.notifier).save(_buildPayload(current));
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Site atualizado com sucesso' : 'Falha ao salvar conteúdo do site'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _uploadImage({
    required String kind,
    required TextEditingController target,
  }) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        imageQuality: 88,
      );
      if (file == null) return;

      setState(() => _uploadingKind = kind);
      final api = ref.read(websiteApiProvider);
      final result = await api.uploadImage(
        filePath: file.path,
        filename: file.name,
        kind: kind,
      );
      final url = '${result['url'] ?? ''}';
      if (url.isEmpty) {
        throw Exception('Upload sem URL pública');
      }
      setState(() => target.text = url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagem enviada para o AWS S3'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha no upload: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingKind = null);
    }
  }

  Widget _imageField({
    required TextEditingController controller,
    required String kind,
    required String label,
    required Color t1,
    required Color t2,
  }) {
    final url = controller.text.trim();
    final uploading = _uploadingKind == kind;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (url.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.neutral200,
                    alignment: Alignment.center,
                    child: Text('Prévia indisponível', style: TextStyle(color: t2)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          _field(controller, label, t1),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: uploading || _saving
                  ? null
                  : () => _uploadImage(kind: kind, target: controller),
              icon: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(uploading ? 'Enviando para S3...' : 'Enviar imagem (S3)'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(websiteContentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : const Color(0xFFF8FAFC);
    final card = isDark ? AppColors.darkCard : Colors.white;
    final t1 = isDark ? AppColors.darkText : AppColors.lightText;
    final t2 = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    ref.listen(websiteContentProvider, (previous, next) {
      if (!_initialized && !next.loading && next.data.isNotEmpty) {
        setState(() => _hydrate(next.data));
      }
    });

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Conteúdo do site'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: state.loading || _saving || state.data.isEmpty
                ? null
                : () => _save(state.data),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: state.loading && !_initialized
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && !_initialized
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.error!, textAlign: TextAlign.center, style: TextStyle(color: t2)),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => ref.read(websiteContentProvider.notifier).load(),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    children: [
                      Text(
                        'O que você salvar aqui aparece no site público da igreja.',
                        style: TextStyle(color: t2),
                      ),
                      const SizedBox(height: 12),
                      _section(
                        card: card,
                        title: 'Identidade',
                        children: [
                          _field(_brand, 'Nome curto (marca)', t1, requiredField: true),
                          _field(_fullName, 'Nome completo', t1, requiredField: true),
                          _field(_about, 'Sobre (rodapé)', t1, maxLines: 4, requiredField: true),
                        ],
                      ),
                      _section(
                        card: card,
                        title: 'Contato',
                        children: [
                          _field(_addressLine, 'Endereço', t1, requiredField: true),
                          _field(_email, 'E-mail', t1, requiredField: true, keyboard: TextInputType.emailAddress),
                          _field(_facebook, 'Facebook (URL)', t1),
                          _field(_instagram, 'Instagram (URL)', t1),
                          _field(_youtube, 'YouTube (URL)', t1),
                        ],
                      ),
                      _section(
                        card: card,
                        title: 'Série em destaque (home)',
                        children: [
                          _field(_seriesSubtitle, 'Subtítulo', t1, requiredField: true),
                          _field(_seriesTitle, 'Título', t1, requiredField: true),
                          _field(_seriesCaption, 'Legenda', t1, requiredField: true),
                          _imageField(
                            controller: _seriesImage,
                            kind: 'series',
                            label: 'URL da imagem do banner',
                            t1: t1,
                            t2: t2,
                          ),
                        ],
                      ),
                      _section(
                        card: card,
                        title: 'Palavra da semana',
                        children: [
                          _field(_weeklyText, 'Texto bíblico', t1, maxLines: 5, requiredField: true),
                          _field(_weeklyRef, 'Referência', t1, requiredField: true),
                        ],
                      ),
                      _section(
                        card: card,
                        title: 'Eventos e programações',
                        children: [
                          ..._events.asMap().entries.map((entry) {
                            final index = entry.key;
                            final event = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text('Evento ${index + 1}', style: TextStyle(fontWeight: FontWeight.w600, color: t1)),
                                        ),
                                        if (_events.length > 1)
                                          IconButton(
                                            onPressed: () => setState(() {
                                              _events.removeAt(index).dispose();
                                            }),
                                            icon: const Icon(Icons.delete_outline_rounded),
                                          ),
                                      ],
                                    ),
                                    _field(event.title, 'Título', t1, requiredField: true),
                                    _field(event.date, 'Data', t1, requiredField: true),
                                    _field(event.time, 'Horário', t1, requiredField: true),
                                  ],
                                ),
                              ),
                            );
                          }),
                          TextButton.icon(
                            onPressed: () => setState(() => _events.add(_EventDraft())),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Adicionar evento'),
                          ),
                        ],
                      ),
                      _section(
                        card: card,
                        title: 'Nossa liderança',
                        children: [
                          _field(_leaderName, 'Nome', t1, requiredField: true),
                          _field(_leaderRole, 'Cargo / função', t1, requiredField: true),
                          _imageField(
                            controller: _leaderImage,
                            kind: 'leadership',
                            label: 'URL da foto',
                            t1: t1,
                            t2: t2,
                          ),
                          _field(_leaderBio, 'Biografia', t1, maxLines: 8, requiredField: true),
                        ],
                      ),
                      _section(
                        card: card,
                        title: 'Afirmação de fé',
                        children: [
                          Text(
                            'Separe os parágrafos com uma linha em branco.',
                            style: TextStyle(color: t2, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          _field(_faithParagraphs, 'Parágrafos', t1, maxLines: 14, requiredField: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: state.loading || _saving || state.data.isEmpty
                            ? null
                            : () => _save(state.data),
                        child: Text(_saving ? 'Salvando...' : 'Publicar no site'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _section({
    required Color card,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    Color textColor, {
    int maxLines = 1,
    bool requiredField = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: TextStyle(color: textColor),
        validator: requiredField
            ? (value) => (value == null || value.trim().isEmpty) ? 'Obrigatório' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _EventDraft {
  _EventDraft({String title = '', String date = '', String time = ''})
      : title = TextEditingController(text: title),
        date = TextEditingController(text: date),
        time = TextEditingController(text: time);

  final TextEditingController title;
  final TextEditingController date;
  final TextEditingController time;

  void dispose() {
    title.dispose();
    date.dispose();
    time.dispose();
  }
}
