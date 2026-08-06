import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/calendar_date.dart';
import '../providers/event_provider.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  String _type = 'WORSHIP';
  bool _loading = false;

  static const _eventTypes = [
    ('WORSHIP', 'Culto', '✝️'),
    ('EVENT', 'Evento', '🎉'),
    ('REHEARSAL', 'Ensaio', '🎵'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  String _datePayload() {
    final value = _dateCtrl.text.trim();
    final parts = value.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final rawYear = int.tryParse(parts[2]);
      if (day != null && month != null && rawYear != null) {
        final year = rawYear < 100 ? 2000 + rawYear : rawYear;
        return calendarDatePayload(DateTime(year, month, day));
      }
    }
    final parsed = DateTime.tryParse(value);
    return parsed != null ? calendarDatePayload(parsed) : value;
  }

  void _handleSave() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _dateCtrl.text.trim().isEmpty ||
        _startCtrl.text.trim().isEmpty ||
        _endCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(eventListProvider.notifier).create({
        'title': _titleCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
        'type': _type,
        'date': _datePayload(),
        'startTime': _startCtrl.text.trim(),
        'endTime': _endCtrl.text.trim(),
        if (_locCtrl.text.trim().isNotEmpty) 'location': _locCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento criado com sucesso!')),
      );
      context.go('/calendar');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
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
                  _field('Data', _dateCtrl, 'AAAA-MM-DD ou DD/MM/AAAA', t1, t2, card, border),
                  const SizedBox(height: 20),
                  _field('Início', _startCtrl, '19:00', t1, t2, card, border),
                  const SizedBox(height: 20),
                  _field('Término', _endCtrl, '21:00', t1, t2, card, border),
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
