import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../events/data/event_api.dart';
import '../../../members/data/member_api.dart';
import '../../../members/domain/member_model.dart';
import '../../../schedules/data/schedule_api.dart';
import '../../data/deacon_ministry_helper.dart';

class CreateDeaconScaleScreen extends ConsumerStatefulWidget {
  const CreateDeaconScaleScreen({super.key});

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

  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _ministryId;
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
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final memberApi = MemberApi(ref.read(apiClientProvider));
      final ministry = await DeaconMinistryHelper.ensureMinistry(memberApi);
      var members = await memberApi.list(role: 'DIACONO', limit: 100, status: 'ATIVO');
      if (members.isEmpty) {
        members = await memberApi.list(limit: 100, status: 'ATIVO');
      }
      if (!mounted) return;
      setState(() {
        _ministryId = ministry.id;
        _members = members;
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
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
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

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _ministryId == null || _assignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha título e adicione ao menos um diácono')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final eventApi = EventApi(ref.read(apiClientProvider));
      final scheduleApi = ScheduleApi(ref.read(apiClientProvider));

      final dateIso = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).toIso8601String();
      final event = await eventApi.create({
        'title': _titleCtrl.text.trim(),
        'description': 'Escala de diáconos',
        'type': 'WORSHIP',
        'date': dateIso,
        'startTime': _startCtrl.text.trim(),
        'endTime': _endCtrl.text.trim(),
      });

      await scheduleApi.create({
        'eventId': event.id,
        'ministryId': _ministryId,
        'date': dateIso,
        'startTime': _startCtrl.text.trim(),
        'endTime': _endCtrl.text.trim(),
        'positions': _assignments
            .map((a) => {
                  'memberId': a.member.id,
                  'position': a.function,
                })
            .toList(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escala de diáconos criada!')),
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
      return m.name.toLowerCase().contains(query);
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
        title: Text('Nova escala de diáconos', style: TextStyle(color: t1, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _field('Título', _titleCtrl, 'Ex: Culto de domingo', t1, t2, card, border),
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
                              Text(assignment.member.name, style: TextStyle(color: t1, fontWeight: FontWeight.w600)),
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
                Text('Adicionar diácono', style: TextStyle(color: t1, fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                _field('Buscar', _searchCtrl, 'Nome do membro', t1, t2, card, border, onChanged: (_) => setState(() {})),
                const SizedBox(height: 8),
                ...available.take(12).map((member) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(member.name, style: TextStyle(color: t1)),
                      subtitle: Text(member.role, style: TextStyle(color: t2, fontSize: 12)),
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
                    child: Text(_saving ? 'Salvando...' : 'Criar escala', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
