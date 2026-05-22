import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  String _type = 'CULTO';
  bool _loading = false;

  static const _eventTypes = [
    ('CULTO', 'Culto', '✝️'),
    ('REUNIAO', 'Reunião', '👥'),
    ('ESTUDO', 'Estudo', '📖'),
    ('EVENTO_SOCIAL', 'Social', '🎉'),
    ('EVENTO_ESPECIAL', 'Especial', '⭐'),
    ('ESCOLA_DOMINICAL', 'Escola Dominical', '📚'),
    ('JEJUM', 'Jejum', '🙏'),
    ('VIGILIA', 'Vigília', '🌙'),
    ('RETIRO', 'Retiro', '🏕️'),
    ('OUTRO', 'Outro', '📌'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Evento criado com sucesso!')),
      );
      context.go('/calendar');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text('←', style: TextStyle(fontSize: 24)),
                  ),
                  const Spacer(),
                  Text('Novo Evento',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: t1)),
                  const Spacer(),
                  const SizedBox(width: 30),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _field('Título', _titleCtrl, 'Nome do evento', t1, t2, card, border),
                  const SizedBox(height: 20),
                  Text('Tipo de Evento',
                      style: TextStyle(fontSize: 14, color: t2)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _eventTypes.map((e) {
                      final isSelected = _type == e.$1;
                      return GestureDetector(
                        onTap: () => setState(() => _type = e.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF008CFF) : card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF008CFF) : border,
                            ),
                          ),
                          child: Text('${e.$3} ${e.$2}',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? Colors.white : t1)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _field('Data', _dateCtrl, 'DD/MM/YY', t1, t2, card, border),
                  const SizedBox(height: 20),
                  _field('Horário', _timeCtrl, '19:00', t1, t2, card, border),
                  const SizedBox(height: 20),
                  _field('Local', _locCtrl, 'Endereço do evento', t1, t2, card, border),
                  const SizedBox(height: 20),
                  _fieldMultiline('Descrição', _descCtrl, 'Detalhes do evento...', t1, t2, card, border),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _titleCtrl.text.trim().isEmpty ? null : _handleSave,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008CFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _loading ? 'Criando...' : 'Criar Evento',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
      Color t1, Color t2, Color card, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: t2)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: t2),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(fontSize: 16, color: t1),
          ),
        ),
      ],
    );
  }

  Widget _fieldMultiline(String label, TextEditingController ctrl, String hint,
      Color t1, Color t2, Color card, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: t2)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: 4,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: t2),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(fontSize: 16, color: t1, height: 1.4),
          ),
        ),
      ],
    );
  }
}
