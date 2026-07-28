import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/member_model.dart';
import '../providers/member_provider.dart';

class MemberFormScreen extends ConsumerStatefulWidget {
  final String? memberId;
  const MemberFormScreen({super.key, this.memberId});

  bool get isEditing => memberId != null;

  @override
  ConsumerState<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends ConsumerState<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _baptismChurchCtrl = TextEditingController();

  final _zipCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  DateTime? _birthDate;
  DateTime? _baptismDate;
  DateTime? _conversionDate;
  DateTime? _admissionDate;

  String _status = 'ATIVO';
  String _role = 'MEMBRO';
  String? _gender;
  String? _maritalStatus;
  String? _admissionType;
  String? _ministryId;
  bool _isBaptized = false;

  bool _loading = false;
  bool _saving = false;

  static const _statuses = ['ATIVO', 'INATIVO', 'AFASTADO', 'TRANSFERIDO'];
  static const _roles = ['MEMBRO', 'DIACONO', 'PRESBITERO', 'PASTOR'];
  static const _genders = ['Masculino', 'Feminino', 'Outro'];
  static const _marital = ['Solteiro(a)', 'Casado(a)', 'Divorciado(a)', 'Viúvo(a)'];
  static const _admissionTypes = [
    ('BATISMO', 'Batismo'),
    ('TRANSFERENCIA', 'Transferência'),
    ('RECONCILIACAO', 'Reconciliação'),
    ('OUTRO', 'Outro'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      Future.microtask(_loadMember);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _phoneCtrl, _emailCtrl, _occupationCtrl, _notesCtrl, _baptismChurchCtrl,
      _zipCtrl, _streetCtrl, _numberCtrl, _complementCtrl, _neighborhoodCtrl, _cityCtrl, _stateCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMember() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(memberRepositoryProvider).getById(widget.memberId!);
      _fill(result.data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fill(MemberModel member) {
    _nameCtrl.text = member.name;
    _phoneCtrl.text = member.phone ?? '';
    _emailCtrl.text = member.email ?? '';
    _occupationCtrl.text = member.occupation ?? '';
    _notesCtrl.text = member.notes ?? '';
    _baptismChurchCtrl.text = member.baptismChurch ?? '';
    _birthDate = member.birthDate;
    _baptismDate = member.baptismDate;
    _conversionDate = member.conversionDate;
    _admissionDate = member.admissionDate;
    _status = member.status;
    _role = member.role;
    _gender = member.gender;
    _maritalStatus = member.maritalStatus;
    _admissionType = member.admissionType;
    _ministryId = member.ministryId;
    _isBaptized = member.isBaptized;
    final address = member.address;
    if (address != null) {
      _zipCtrl.text = address.zipCode ?? '';
      _streetCtrl.text = address.street ?? '';
      _numberCtrl.text = address.number ?? '';
      _complementCtrl.text = address.complement ?? '';
      _neighborhoodCtrl.text = address.neighborhood ?? '';
      _cityCtrl.text = address.city ?? '';
      _stateCtrl.text = address.state ?? '';
    }
    setState(() {});
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickDate({required DateTime? current, required ValueChanged<DateTime?> onPicked}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) onPicked(picked);
  }

  Map<String, dynamic> _payload() {
    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'status': _status,
      'role': _role,
      'isBaptized': _isBaptized,
    };
    if (_phoneCtrl.text.trim().isNotEmpty) data['phone'] = _phoneCtrl.text.trim();
    if (_emailCtrl.text.trim().isNotEmpty) data['email'] = _emailCtrl.text.trim();
    if (_occupationCtrl.text.trim().isNotEmpty) data['occupation'] = _occupationCtrl.text.trim();
    if (_notesCtrl.text.trim().isNotEmpty) data['notes'] = _notesCtrl.text.trim();
    if (_gender != null) data['gender'] = _gender;
    if (_maritalStatus != null) data['maritalStatus'] = _maritalStatus;
    if (_ministryId != null) data['ministryId'] = _ministryId;
    if (_birthDate != null) data['dateOfBirth'] = _birthDate!.toIso8601String();
    if (_baptismDate != null) data['baptismDate'] = _baptismDate!.toIso8601String();
    if (_conversionDate != null) data['conversionDate'] = _conversionDate!.toIso8601String();
    if (_admissionDate != null) data['admissionDate'] = _admissionDate!.toIso8601String();
    if (_admissionType != null) data['admissionType'] = _admissionType;
    if (_baptismChurchCtrl.text.trim().isNotEmpty) data['baptismChurch'] = _baptismChurchCtrl.text.trim();

    final hasAddress = _streetCtrl.text.trim().isNotEmpty &&
        _neighborhoodCtrl.text.trim().isNotEmpty &&
        _cityCtrl.text.trim().isNotEmpty &&
        _stateCtrl.text.trim().isNotEmpty &&
        _zipCtrl.text.trim().isNotEmpty;
    if (hasAddress) {
      data['address'] = {
        'street': _streetCtrl.text.trim(),
        'number': _numberCtrl.text.trim().isEmpty ? null : _numberCtrl.text.trim(),
        'complement': _complementCtrl.text.trim().isEmpty ? null : _complementCtrl.text.trim(),
        'neighborhood': _neighborhoodCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim().toUpperCase(),
        'zipCode': _zipCtrl.text.trim(),
      };
    }
    return data;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = _payload();
      if (widget.isEditing) {
        await ref.read(memberListProvider.notifier).update(widget.memberId!, payload);
        if (!mounted) return;
        ref.invalidate(memberDetailProvider(widget.memberId!));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membro atualizado')));
        context.pop();
      } else {
        final created = await ref.read(memberListProvider.notifier).create(payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membro cadastrado')));
        context.go(AppRoutes.memberDetail(created.id));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ministries = ref.watch(ministryListProvider).valueOrNull ?? const <MinistryModel>[];
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
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: t1),
        ),
        title: Text(
          widget.isEditing ? 'Editar membro' : 'Novo membro',
          style: TextStyle(color: t1, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  _section('Dados básicos', t1),
                  _text('Nome completo *', _nameCtrl, t1, t2, card, border, requiredField: true),
                  _text('Telefone', _phoneCtrl, t1, t2, card, border, keyboard: TextInputType.phone),
                  _text('E-mail', _emailCtrl, t1, t2, card, border, keyboard: TextInputType.emailAddress),
                  _dateField('Data de nascimento', _birthDate, () => _pickDate(current: _birthDate, onPicked: (d) => setState(() => _birthDate = d)), t1, t2, card, border),
                  _dropdown<String>(
                    'Gênero',
                    _genders.contains(_gender) ? _gender : null,
                    _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    (v) => setState(() => _gender = v),
                    t1, t2, card, border,
                  ),
                  _dropdown<String>(
                    'Estado civil',
                    _marital.contains(_maritalStatus) ? _maritalStatus : null,
                    _marital.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    (v) => setState(() => _maritalStatus = v),
                    t1, t2, card, border,
                  ),
                  _dropdown<String>(
                    'Status',
                    _status,
                    _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    (v) => setState(() => _status = v ?? 'ATIVO'),
                    t1, t2, card, border,
                  ),
                  _dropdown<String>(
                    'Função',
                    _role,
                    _roles.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    (v) => setState(() => _role = v ?? 'MEMBRO'),
                    t1, t2, card, border,
                  ),
                  _text('Profissão', _occupationCtrl, t1, t2, card, border),
                  const SizedBox(height: 20),
                  _section('Vida espiritual', t1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Batizado', style: TextStyle(color: t1)),
                    value: _isBaptized,
                    activeColor: const Color(0xFF008CFF),
                    onChanged: (v) => setState(() => _isBaptized = v),
                  ),
                  if (_isBaptized) ...[
                    _dateField('Data do batismo', _baptismDate, () => _pickDate(current: _baptismDate, onPicked: (d) => setState(() => _baptismDate = d)), t1, t2, card, border),
                    _text('Igreja do batismo', _baptismChurchCtrl, t1, t2, card, border),
                  ],
                  _dateField('Data de conversão', _conversionDate, () => _pickDate(current: _conversionDate, onPicked: (d) => setState(() => _conversionDate = d)), t1, t2, card, border),
                  _dateField('Data de admissão', _admissionDate, () => _pickDate(current: _admissionDate, onPicked: (d) => setState(() => _admissionDate = d)), t1, t2, card, border),
                  _dropdown<String>(
                    'Tipo de admissão',
                    _admissionTypes.any((e) => e.$1 == _admissionType) ? _admissionType : null,
                    _admissionTypes.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2))).toList(),
                    (v) => setState(() => _admissionType = v),
                    t1, t2, card, border,
                  ),
                  _dropdown<String>(
                    'Ministério',
                    ministries.any((m) => m.id == _ministryId) ? _ministryId : null,
                    ministries.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                    (v) => setState(() => _ministryId = v),
                    t1, t2, card, border,
                  ),
                  _text('Observações', _notesCtrl, t1, t2, card, border, maxLines: 3),
                  const SizedBox(height: 20),
                  _section('Endereço', t1),
                  _text('CEP', _zipCtrl, t1, t2, card, border, keyboard: TextInputType.number),
                  _text('Rua', _streetCtrl, t1, t2, card, border),
                  Row(
                    children: [
                      Expanded(child: _text('Número', _numberCtrl, t1, t2, card, border)),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: _text('Complemento', _complementCtrl, t1, t2, card, border)),
                    ],
                  ),
                  _text('Bairro', _neighborhoodCtrl, t1, t2, card, border),
                  Row(
                    children: [
                      Expanded(flex: 3, child: _text('Cidade', _cityCtrl, t1, t2, card, border)),
                      const SizedBox(width: 12),
                      Expanded(child: _text('UF', _stateCtrl, t1, t2, card, border)),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _saving || _loading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008CFF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _saving ? 'Salvando...' : (widget.isEditing ? 'Salvar alterações' : 'Cadastrar membro'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, Color t1) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t1)),
    );
  }

  Widget _text(
    String label,
    TextEditingController ctrl,
    Color t1,
    Color t2,
    Color card,
    Color border, {
    bool requiredField = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: t2, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: TextFormField(
              controller: ctrl,
              keyboardType: keyboard,
              maxLines: maxLines,
              validator: requiredField
                  ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null
                  : null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
              style: TextStyle(color: t1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime? value,
    VoidCallback onTap,
    Color t1,
    Color t2,
    Color card,
    Color border,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: t2, fontSize: 13)),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
              child: Text(value == null ? 'Selecionar' : _fmt(value), style: TextStyle(color: value == null ? t2 : t1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> onChanged,
    Color t1,
    Color t2,
    Color card,
    Color border,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: t2, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                hint: Text('Selecionar', style: TextStyle(color: t2)),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
