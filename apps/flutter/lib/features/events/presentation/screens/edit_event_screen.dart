import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/event_provider.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final String id;
  const EditEventScreen({super.key, required this.id});

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  void _handleSave() async {
    setState(() => _saving = true);
    try {
      await ref.read(eventListProvider.notifier).update(widget.id, {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'date': _dateCtrl.text.trim(),
        'startTime': _timeCtrl.text.trim(),
        'location': _locCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento atualizado!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
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
    final detail = ref.watch(eventDetailProvider(widget.id));

    if (detail.loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final event = detail.event;
    if (event != null && _titleCtrl.text.isEmpty) {
      _titleCtrl.text = event.title;
      _dateCtrl.text = event.date.toIso8601String().substring(0, 10);
      _timeCtrl.text = event.startTime;
      _locCtrl.text = event.location ?? '';
      _descCtrl.text = event.description ?? '';
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('←', style: TextStyle(fontSize: 24)),
          ),
        ),
        title: Text('Editar Evento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t1)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _handleSave,
              child: Text(_saving ? 'Salvando...' : 'Salvar',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF008CFF))),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field('Título', _titleCtrl, 'Nome do evento', t1, t2, card, border),
          const SizedBox(height: 20),
          _field('Data', _dateCtrl, 'DD/MM/YY', t1, t2, card, border),
          const SizedBox(height: 20),
          _field('Horário', _timeCtrl, '19:00', t1, t2, card, border),
          const SizedBox(height: 20),
          _field('Local', _locCtrl, 'Endereço do evento', t1, t2, card, border),
          const SizedBox(height: 20),
          _fieldMultiline('Descrição', _descCtrl, 'Detalhes do evento...', t1, t2, card, border),
        ],
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
