import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/utils/error_helper.dart';
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
  final _locCtrl = TextEditingController();

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _type = 'WORSHIP';
  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;
  bool _filled = false;
  String? _error;

  static const _eventTypes = [
    ('WORSHIP', 'Culto'),
    ('EVENT', 'Evento'),
    ('REHEARSAL', 'Ensaio'),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(eventDetailProvider(widget.id).notifier).load();
      final event = ref.read(eventDetailProvider(widget.id)).event;
      if (event == null) throw Exception('Evento não encontrado');
      if (!_filled) {
        _titleCtrl.text = event.title;
        _descCtrl.text = event.description ?? '';
        _locCtrl.text = event.location ?? '';
        _type = event.type;
        _date = calendarDate(event.date);
        _startTime = _parseTime(event.startTime) ?? const TimeOfDay(hour: 19, minute: 0);
        _endTime = _parseTime(event.endTime) ?? const TimeOfDay(hour: 21, minute: 0);
        _filled = true;
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = formatError(e);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 19, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 21, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _handleSave() async {
    if (_titleCtrl.text.trim().isEmpty || _date == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha título, data e horários')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(eventListProvider.notifier).update(widget.id, {
        'title': _titleCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        'type': _type,
        'date': calendarDatePayload(_date!),
        'startTime': _fmtTime(_startTime!),
        'endTime': _fmtTime(_endTime!),
        if (_locCtrl.text.trim().isNotEmpty) 'location': _locCtrl.text.trim(),
      });
      if (!mounted) return;
      ref.invalidate(eventDetailProvider(widget.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento atualizado!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${formatError(e)}')),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir evento'),
        content: Text('Tem certeza que deseja excluir "${_titleCtrl.text.trim()}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(eventListProvider.notifier).delete(widget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento excluído')),
      );
      context.go('/calendar');
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: ${formatError(e)}')),
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
    final canDelete = ref.watch(authProvider).user?.hasPermission('events_delete') == true;

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t1),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t1),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text(_error!, style: TextStyle(color: t2))),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: t1),
          onPressed: () => context.pop(),
        ),
        title: Text('Editar evento', style: TextStyle(color: t1, fontWeight: FontWeight.w600)),
        actions: [
          if (canDelete)
            IconButton(
              tooltip: 'Excluir',
              onPressed: _saving || _deleting ? null : _handleDelete,
              icon: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          _field('Título', _titleCtrl, 'Nome do evento', t1, t2, card, border),
          const SizedBox(height: 20),
          Text('Tipo de evento', style: TextStyle(fontSize: 14, color: t2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _eventTypes.map((e) {
              final isSelected = _type == e.$1;
              return FilterChip(
                label: Text(e.$2),
                selected: isSelected,
                onSelected: (_) => setState(() => _type = e.$1),
                selectedColor: const Color(0xFF008CFF).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF008CFF),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF008CFF) : t1,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                backgroundColor: card,
                side: BorderSide(color: isSelected ? const Color(0xFF008CFF) : border),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _pickerField(
            label: 'Data',
            value: _date == null ? 'Selecionar' : _fmtDate(_date!),
            empty: _date == null,
            onTap: _pickDate,
            t1: t1,
            t2: t2,
            card: card,
            border: border,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _pickerField(
                  label: 'Início',
                  value: _startTime == null ? 'Selecionar' : _fmtTime(_startTime!),
                  empty: _startTime == null,
                  onTap: () => _pickTime(isStart: true),
                  t1: t1,
                  t2: t2,
                  card: card,
                  border: border,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _pickerField(
                  label: 'Término',
                  value: _endTime == null ? 'Selecionar' : _fmtTime(_endTime!),
                  empty: _endTime == null,
                  onTap: () => _pickTime(isStart: false),
                  t1: t1,
                  t2: t2,
                  card: card,
                  border: border,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _field('Local', _locCtrl, 'Endereço do evento', t1, t2, card, border),
          const SizedBox(height: 20),
          _fieldMultiline('Descrição', _descCtrl, 'Detalhes do evento...', t1, t2, card, border),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _saving || _deleting ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008CFF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _saving ? 'Salvando...' : 'Salvar alterações',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickerField({
    required String label,
    required String value,
    required bool empty,
    required VoidCallback onTap,
    required Color t1,
    required Color t2,
    required Color card,
    required Color border,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: t2)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Text(value, style: TextStyle(fontSize: 16, color: empty ? t2 : t1)),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint,
    Color t1,
    Color t2,
    Color card,
    Color border,
  ) {
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

  Widget _fieldMultiline(
    String label,
    TextEditingController ctrl,
    String hint,
    Color t1,
    Color t2,
    Color card,
    Color border,
  ) {
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
