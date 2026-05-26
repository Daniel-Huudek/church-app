import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/schedule_provider.dart';

class CreateScheduleScreen extends ConsumerStatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  ConsumerState<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends ConsumerState<CreateScheduleScreen> {
  final _eventCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _eventCtrl.dispose();
    _dateCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_eventCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(scheduleListProvider.notifier).create({
        'eventName': _eventCtrl.text.trim(),
        'date': _dateCtrl.text.trim(),
        'startTime': _startCtrl.text.trim(),
        'endTime': _endCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escala criada com sucesso!')),
      );
      context.pop();
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
        title: Text('Nova Escala', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t1)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field('Evento', _eventCtrl, 'Nome do evento', t1, t2, card, border),
          const SizedBox(height: 20),
          _field('Data', _dateCtrl, 'DD/MM/YY', t1, t2, card, border),
          const SizedBox(height: 20),
          _field('Início', _startCtrl, '19:00', t1, t2, card, border),
          const SizedBox(height: 20),
          _field('Término', _endCtrl, '21:00', t1, t2, card, border),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _eventCtrl.text.trim().isEmpty ? null : _handleSave,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF008CFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _loading ? 'Criando...' : 'Criar Escala',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ),
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
}
