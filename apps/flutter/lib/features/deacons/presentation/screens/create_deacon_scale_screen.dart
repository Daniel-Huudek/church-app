import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../shared/utils/person_name.dart';
import '../../../events/data/event_api.dart';
import '../../../events/domain/event_model.dart';
import '../../../events/presentation/widgets/event_source_section.dart';
import '../../../members/data/member_api.dart';
import '../../../members/domain/member_model.dart';
import '../../../schedules/data/schedule_api.dart';
import '../../data/deacon_ministry_helper.dart';

class CreateDeaconScaleScreen extends ConsumerStatefulWidget {
  final String? scheduleId;
  const CreateDeaconScaleScreen({super.key, this.scheduleId});

  @override
  ConsumerState<CreateDeaconScaleScreen> createState() => _CreateDeaconScaleScreenState();
}

class _CreateDeaconScaleScreenState extends ConsumerState<CreateDeaconScaleScreen> {
  static const _functions = [
    'Porta Principal',
    'Porta Lateral',
    'Ceia',
    'Oferta',
    'Estacionamento',
    'Recepção',
    'Apoio',
    'Outro',
  ];

  final _titleCtrl = TextEditingController();
  final _startCtrl = TextEditingController(text: '19:00');
  final _endCtrl = TextEditingController(text: '21:00');
  final _searchCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  bool get _isEditing => widget.scheduleId != null;
  String? _ministryId;
  String? _eventId;
  EventLinkMode _eventLinkMode = EventLinkMode.existing;
  List<EventModel> _availableEvents = [];
  Set<String> _eventsWithDeaconScale = {};
  List<MemberModel> _members = [];
  final List<_DeaconAssignment> _assignments = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _searchCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _datePayload(DateTime date) => calendarDatePayload(date);

  void _applyEvent(EventModel event) {
    _eventId = event.id;
    _titleCtrl.text = event.title;
    _selectedDate = calendarDate(event.date);
    _startCtrl.text = event.startTime;
    _endCtrl.text = event.endTime ?? '21:00';
  }

  void _clearEventFields() {
    _eventId = null;
    _titleCtrl.clear();
    _selectedDate = DateTime.now();
    _startCtrl.text = '19:00';
    _endCtrl.text = '21:00';
  }

  String _normalizeFunction(String? value) {
    if (value == null || value.isEmpty) return _functions.first;
    if (_functions.contains(value)) return value;
    return 'Outro';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final memberApi = MemberApi(ref.read(apiClientProvider));
      final eventApi = EventApi(ref.read(apiClientProvider));
      final scheduleApi = ScheduleApi(ref.read(apiClientProvider));

      final ministry = await DeaconMinistryHelper.ensureMinistry(memberApi);
      final members = await memberApi.list(
        ministryId: ministry.id,
        limit: 100,
        status: 'ATIVO',
      );

      List<EventModel> events = [];
      Set<String> usedEventIds = {};
      if (!_isEditing) {
        try {
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
          final end = start.add(const Duration(days: 120));
          events = await eventApi.list(startDate: start, endDate: end);
          events.sort((a, b) => a.date.compareTo(b.date));
        } catch (_) {}

        try {
          final schedules = await scheduleApi.list(ministryId: ministry.id);
          usedEventIds = schedules
              .map((s) => s.eventId)
              .whereType<String>()
              .toSet();
        } catch (_) {}
      }

      final assignments = <_DeaconAssignment>[];
      if (_isEditing && widget.scheduleId != null) {
        final schedule = await scheduleApi.getById(widget.scheduleId!);
        _ministryId = schedule.ministryId ?? ministry.id;
        _eventLinkMode = EventLinkMode.existing;
        _selectedDate = calendarDate(schedule.date);
        _startCtrl.text = schedule.startTime;
        _endCtrl.text = schedule.endTime;

        if (schedule.eventId != null) {
          try {
            final event = await eventApi.getById(schedule.eventId!);
            _applyEvent(event);
            _notesCtrl.text = (event.description != null && event.description != 'Escala de diáconos')
                ? event.description!
                : '';
          } catch (_) {
            _eventId = schedule.eventId;
            _titleCtrl.text = schedule.eventName ?? 'Escala de diáconos';
          }
        } else {
          _titleCtrl.text = schedule.eventName ?? 'Escala de diáconos';
        }

        for (final position in schedule.positionDetails) {
          final memberId = position.memberId;
          if (memberId == null) continue;
          MemberModel? member;
          final byId = members.where((m) => m.id == memberId).toList();
          if (byId.isNotEmpty) {
            member = byId.first;
          } else {
            try {
              member = await memberApi.getById(memberId);
            } catch (_) {
              member = MemberModel(
                id: memberId,
                name: position.memberName ?? 'Membro',
                createdAt: DateTime.now(),
              );
            }
          }
          assignments.add(
            _DeaconAssignment(
              member: member,
              function: _normalizeFunction(position.position),
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _ministryId ??= ministry.id;
        _members = members;
        _availableEvents = events;
        _eventsWithDeaconScale = usedEventIds;
        if (!_isEditing) {
          _eventLinkMode = events.isEmpty ? EventLinkMode.createNew : EventLinkMode.existing;
        }
        _assignments
          ..clear()
          ..addAll(assignments);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar: $e')));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _addAssignment(MemberModel member) {
    if (_assignments.any((a) => a.member.id == member.id)) return;
    setState(() {
      _assignments.add(_DeaconAssignment(member: member, function: _functions.first));
    });
  }

  String _memberLabel(MemberModel member) {
    return preferredPersonName(name: member.name, nickname: member.nickname);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _ministryId == null || _assignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha título e adicione ao menos um diácono')),
      );
      return;
    }
    if (!_isEditing &&
        _eventLinkMode == EventLinkMode.existing &&
        (_eventId == null || _eventId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um evento existente')),
      );
      return;
    }
    if (_isEditing && (_eventId == null || _eventId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento da escala não encontrado')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final eventApi = EventApi(ref.read(apiClientProvider));
      final scheduleApi = ScheduleApi(ref.read(apiClientProvider));
      final dateIso = _datePayload(_selectedDate);
      final eventPayload = {
        'title': _titleCtrl.text.trim(),
        'description': _notesCtrl.text.trim().isEmpty
            ? 'Escala de diáconos'
            : _notesCtrl.text.trim(),
        'type': 'WORSHIP',
        'date': dateIso,
        'startTime': _startCtrl.text.trim(),
        'endTime': _endCtrl.text.trim(),
      };
      final positions = _assignments
          .map((a) => {
                'memberId': a.member.id,
                'position': a.function,
              })
          .toList();

      if (_isEditing && widget.scheduleId != null) {
        await eventApi.update(_eventId!, {
          'title': _titleCtrl.text.trim(),
          'date': dateIso,
          'startTime': _startCtrl.text.trim(),
          'endTime': _endCtrl.text.trim(),
          if (_notesCtrl.text.trim().isNotEmpty) 'description': _notesCtrl.text.trim(),
        });
        await scheduleApi.update(widget.scheduleId!, {
          'eventId': _eventId,
          'ministryId': _ministryId,
          'date': dateIso,
          'startTime': _startCtrl.text.trim(),
          'endTime': _endCtrl.text.trim(),
          'positions': positions,
        });
      } else {
        late final String linkedEventId;
        if (_eventLinkMode == EventLinkMode.existing) {
          linkedEventId = _eventId!;
          if (_eventsWithDeaconScale.contains(linkedEventId)) {
            throw Exception('Este evento já possui escala de diáconos');
          }
          await eventApi.update(linkedEventId, {
            'title': _titleCtrl.text.trim(),
            'date': dateIso,
            'startTime': _startCtrl.text.trim(),
            'endTime': _endCtrl.text.trim(),
            if (_notesCtrl.text.trim().isNotEmpty) 'description': _notesCtrl.text.trim(),
          });
        } else {
          final event = await eventApi.create(eventPayload);
          linkedEventId = event.id;
        }

        await scheduleApi.create({
          'eventId': linkedEventId,
          'ministryId': _ministryId,
          'date': dateIso,
          'startTime': _startCtrl.text.trim(),
          'endTime': _endCtrl.text.trim(),
          'positions': positions,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Escala atualizada!' : 'Escala de diáconos criada!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
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

    final query = _searchCtrl.text.trim().toLowerCase();
    final available = _members.where((m) {
      final selected = _assignments.any((a) => a.member.id == m.id);
      if (selected) return false;
      if (query.isEmpty) return true;
      return _memberLabel(m).toLowerCase().contains(query) ||
          m.name.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: t1),
        ),
        title: Text(
          _isEditing ? 'Editar escala de diáconos' : 'Nova escala de diáconos',
          style: TextStyle(color: t1, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!_isEditing)
                  EventSourceSection(
                    isDark: isDark,
                    mode: _eventLinkMode,
                    onModeChanged: (mode) {
                      setState(() {
                        _eventLinkMode = mode;
                        if (mode == EventLinkMode.createNew) {
                          _clearEventFields();
                        } else if (_eventId != null) {
                          final match = _availableEvents.where((e) => e.id == _eventId);
                          if (match.isNotEmpty) _applyEvent(match.first);
                        }
                      });
                    },
                    events: _availableEvents,
                    unavailableEventIds: _eventsWithDeaconScale,
                    selectedEventId: _eventId,
                    onSelectEvent: (event) => setState(() => _applyEvent(event)),
                    unavailableHint: 'Já tem escala de diáconos',
                  ),
                if (!_isEditing) const SizedBox(height: 16),
                _field('Título do evento', _titleCtrl, 'Ex: Culto de domingo', t1, t2, card, border),
                const SizedBox(height: 16),
                Text('Data', style: TextStyle(color: t2, fontSize: 14)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                    child: Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                      style: TextStyle(color: t1, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _field('Início', _startCtrl, '19:00', t1, t2, card, border)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Término', _endCtrl, '21:00', t1, t2, card, border)),
                  ],
                ),
                const SizedBox(height: 16),
                _field(
                  'Observações da escala',
                  _notesCtrl,
                  'Info específica dos diáconos (opcional)',
                  t1,
                  t2,
                  card,
                  border,
                ),
                const SizedBox(height: 24),
                Text('Diáconos escalados', style: TextStyle(color: t1, fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                if (_assignments.isEmpty)
                  Text('Nenhum diácono adicionado ainda.', style: TextStyle(color: t2)),
                ..._assignments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final assignment = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_memberLabel(assignment.member), style: TextStyle(color: t1, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: assignment.function,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: bg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: _functions
                                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _assignments[index] = assignment.copyWith(function: value));
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _assignments.removeAt(index)),
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Text('Adicionar diácono do ministério', style: TextStyle(color: t1, fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                _field('Buscar', _searchCtrl, 'Nome do membro', t1, t2, card, border, onChanged: (_) => setState(() {})),
                const SizedBox(height: 8),
                if (available.isEmpty)
                  Text(
                    _members.isEmpty
                        ? 'Nenhum membro no ministério de Diáconos. Cadastre membros nesse ministério.'
                        : (query.isEmpty
                            ? 'Todos os membros do diaconato já foram adicionados'
                            : 'Nenhum membro encontrado'),
                    style: TextStyle(color: t2),
                  )
                else
                  ...available.take(20).map((member) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_memberLabel(member), style: TextStyle(color: t1)),
                        subtitle: Text(
                          [
                            if (member.ministryName != null && member.ministryName!.isNotEmpty) member.ministryName!,
                            if (member.email != null) member.email!,
                          ].join(' · '),
                          style: TextStyle(color: t2, fontSize: 12),
                        ),
                        trailing: IconButton(
                          onPressed: () => _addAssignment(member),
                          icon: const Icon(Icons.add_circle, color: Color(0xFF008CFF)),
                        ),
                      )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008CFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _saving
                          ? 'Salvando...'
                          : (_isEditing ? 'Salvar alterações' : 'Criar escala'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint,
    Color t1,
    Color t2,
    Color card,
    Color border, {
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: t2, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
          child: TextField(
            controller: ctrl,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: t2),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(color: t1, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _DeaconAssignment {
  final MemberModel member;
  final String function;

  const _DeaconAssignment({required this.member, required this.function});

  _DeaconAssignment copyWith({MemberModel? member, String? function}) {
    return _DeaconAssignment(
      member: member ?? this.member,
      function: function ?? this.function,
    );
  }
}
