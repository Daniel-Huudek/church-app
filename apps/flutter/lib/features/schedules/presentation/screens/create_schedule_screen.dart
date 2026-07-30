import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../events/domain/event_model.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../members/domain/member_model.dart';
import '../../../members/presentation/providers/member_provider.dart';
import '../../../../shared/utils/person_name.dart';
import '../providers/schedule_provider.dart';

class CreateScheduleScreen extends ConsumerStatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  ConsumerState<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends ConsumerState<CreateScheduleScreen> {
  final _dateCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _memberIdCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final List<_SchedulePositionInput> _positions = [];
  String? _selectedEventId;
  String? _selectedMinistryId;
  String? _selectedMemberId;
  bool _loading = false;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _memberIdCtrl.dispose();
    _positionCtrl.dispose();
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
        return DateTime(year, month, day).toIso8601String();
      }
    }
    final parsed = DateTime.tryParse(value);
    return parsed?.toIso8601String() ?? value;
  }

  _SchedulePositionInput? _pendingPosition() {
    final memberId = (_selectedMemberId ?? _memberIdCtrl.text).trim();
    final position = _positionCtrl.text.trim();
    if (memberId.isEmpty || position.isEmpty) return null;
    return _SchedulePositionInput(memberId: memberId, position: position);
  }

  String _memberLabel(MemberModel member) {
    return preferredPersonName(name: member.name, nickname: member.nickname);
  }

  String _memberLabelById(List<MemberModel> members, String memberId) {
    for (final member in members) {
      if (member.id == memberId) return _memberLabel(member);
    }
    return memberId;
  }

  void _addPosition() {
    final position = _pendingPosition();
    if (position == null) return;
    setState(() {
      _positions.add(position);
      _selectedMemberId = null;
      _memberIdCtrl.clear();
      _positionCtrl.clear();
    });
  }

  void _handleSave() async {
    final pendingPosition = _pendingPosition();
    final positions = [
      ..._positions,
      if (pendingPosition != null) pendingPosition,
    ];
    if (_selectedEventId == null ||
        _selectedMinistryId == null ||
        _dateCtrl.text.trim().isEmpty ||
        _startCtrl.text.trim().isEmpty ||
        _endCtrl.text.trim().isEmpty ||
        positions.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(scheduleListProvider.notifier).create({
        'eventId': _selectedEventId,
        'ministryId': _selectedMinistryId,
        'date': _datePayload(),
        'startTime': _startCtrl.text.trim(),
        'endTime': _endCtrl.text.trim(),
        'positions': positions.map((p) => p.toJson()).toList(),
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
    final eventState = ref.watch(eventListProvider);
    final memberState = ref.watch(memberListProvider);
    final ministryState = ref.watch(ministryListProvider);
    final ministries = ministryState.valueOrNull ?? const <MinistryModel>[];

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
          _dropdown<EventModel>(
            label: 'Evento',
            value: _selectedEventId,
            items: eventState.data,
            getValue: (event) => event.id,
            getLabel: (event) =>
                '${event.title} - ${event.date.toIso8601String().substring(0, 10)}',
            hint: eventState.loading ? 'Carregando eventos...' : 'Selecione o evento',
            t1: t1,
            t2: t2,
            card: card,
            border: border,
            onChanged: (value) => setState(() => _selectedEventId = value),
          ),
          const SizedBox(height: 20),
          _dropdown<MinistryModel>(
            label: 'Ministério',
            value: _selectedMinistryId,
            items: ministries,
            getValue: (ministry) => ministry.id,
            getLabel: (ministry) => ministry.name,
            hint: ministryState.isLoading ? 'Carregando ministérios...' : 'Selecione o ministério',
            t1: t1,
            t2: t2,
            card: card,
            border: border,
            onChanged: (value) => setState(() => _selectedMinistryId = value),
          ),
          const SizedBox(height: 20),
          _field('Data', _dateCtrl, 'AAAA-MM-DD ou DD/MM/AAAA', t1, t2, card, border),
          const SizedBox(height: 20),
          _field('Início', _startCtrl, '19:00', t1, t2, card, border),
          const SizedBox(height: 20),
          _field('Término', _endCtrl, '21:00', t1, t2, card, border),
          const SizedBox(height: 28),
          Text('Posições', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t1)),
          const SizedBox(height: 12),
          _dropdown<MemberModel>(
            label: 'Membro',
            value: _selectedMemberId,
            items: memberState.data,
            getValue: (member) => member.id,
            getLabel: (member) => _memberLabel(member),
            hint: memberState.loading ? 'Carregando membros...' : 'Selecione um membro',
            t1: t1,
            t2: t2,
            card: card,
            border: border,
            onChanged: (value) => setState(() {
              _selectedMemberId = value;
              _memberIdCtrl.clear();
            }),
          ),
          const SizedBox(height: 12),
          _field('Ou informe o ID do membro', _memberIdCtrl, 'UUID do membro', t1, t2, card, border),
          const SizedBox(height: 12),
          _field('Função', _positionCtrl, 'Ex: Vocal, Recepção, Som', t1, t2, card, border),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addPosition,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar posição'),
            ),
          ),
          if (_positions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._positions.asMap().entries.map((entry) {
              final index = entry.key;
              final position = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${position.position} - ${_memberLabelById(memberState.data, position.memberId)}',
                        style: TextStyle(color: t1),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: t2),
                      onPressed: () => setState(() => _positions.removeAt(index)),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _loading ? null : _handleSave,
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

  Widget _dropdown<T>({
    required String label,
    required String? value,
    required List<T> items,
    required String Function(T item) getValue,
    required String Function(T item) getLabel,
    required String hint,
    required Color t1,
    required Color t2,
    required Color card,
    required Color border,
    required ValueChanged<String?> onChanged,
  }) {
    final values = items.map(getValue).toSet();
    final selectedValue = value != null && values.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: t2)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedValue,
          isExpanded: true,
          dropdownColor: card,
          decoration: InputDecoration(
            filled: true,
            fillColor: card,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: border),
            ),
          ),
          hint: Text(hint, style: TextStyle(color: t2)),
          items: items
              .map((item) => DropdownMenuItem(
                    value: getValue(item),
                    child: Text(
                      getLabel(item),
                      style: TextStyle(color: t1),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SchedulePositionInput {
  final String memberId;
  final String position;

  const _SchedulePositionInput({
    required this.memberId,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'position': position,
      };
}
