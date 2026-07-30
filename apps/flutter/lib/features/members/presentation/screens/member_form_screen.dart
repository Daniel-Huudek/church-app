import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/utils/error_helper.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../../data/cep_lookup_service.dart';
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
  final _nicknameCtrl = TextEditingController();
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
  final Set<String> _ministryIds = {};
  bool _isBaptized = false;
  String? _linkedUserId;
  String? _originalUserId;
  List<UserModel> _appUsers = const [];
  bool _usersLoaded = false;

  bool _loading = false;
  bool _saving = false;
  bool _lookingUpCep = false;
  String? _lastLookedUpCep;

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
    Future.microtask(_loadAppUsers);
    if (widget.isEditing) {
      Future.microtask(_loadMember);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _nicknameCtrl, _phoneCtrl, _emailCtrl, _occupationCtrl, _notesCtrl, _baptismChurchCtrl,
      _zipCtrl, _streetCtrl, _numberCtrl, _complementCtrl, _neighborhoodCtrl, _cityCtrl, _stateCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAppUsers() async {
    try {
      final users = await ref.read(userApiProvider).list(page: 1, limit: 200);
      if (!mounted) return;
      setState(() {
        _appUsers = users..sort((a, b) => a.name.compareTo(b.name));
        _usersLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _usersLoaded = true);
    }
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
    _nicknameCtrl.text = member.nickname ?? '';
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
    _linkedUserId = member.userId;
    _originalUserId = member.userId;
    _ministryIds
      ..clear()
      ..addAll(member.ministryIds.isNotEmpty
          ? member.ministryIds
          : (member.ministryId != null ? [member.ministryId!] : const <String>[]));
    _isBaptized = member.isBaptized;
    final address = member.address;
    if (address != null) {
      _zipCtrl.text = formatCep(address.zipCode ?? '');
      _lastLookedUpCep = normalizeCep(_zipCtrl.text);
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

  Future<void> _onCepChanged(String value) async {
    final formatted = formatCep(value);
    if (_zipCtrl.text != formatted) {
      final selection = formatted.length;
      _zipCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: selection),
      );
    }

    final digits = normalizeCep(formatted);
    if (digits.length != 8) {
      _lastLookedUpCep = null;
      return;
    }
    if (digits == _lastLookedUpCep || _lookingUpCep) return;

    final requested = digits;
    setState(() => _lookingUpCep = true);
    try {
      final address = await ref.read(cepLookupServiceProvider).lookup(requested);
      if (!mounted || address == null) return;
      _lastLookedUpCep = requested;
      setState(() {
        _zipCtrl.text = address.zipCode;
        if (address.street.isNotEmpty) _streetCtrl.text = address.street;
        if (address.neighborhood.isNotEmpty) _neighborhoodCtrl.text = address.neighborhood;
        _cityCtrl.text = address.city;
        _stateCtrl.text = address.state;
      });
    } on CepNotFoundException {
      if (!mounted) return;
      _lastLookedUpCep = requested;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CEP não encontrado')),
      );
    } on DioException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível consultar o CEP. Tente novamente.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível consultar o CEP. Tente novamente.')),
      );
    } finally {
      if (mounted) {
        setState(() => _lookingUpCep = false);
        final current = normalizeCep(_zipCtrl.text);
        // Só busca de novo se o usuário alterou o CEP durante a consulta.
        if (current.length == 8 && current != requested && current != _lastLookedUpCep) {
          _onCepChanged(_zipCtrl.text);
        }
      }
    }
  }

  Map<String, dynamic> _payload() {
    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'status': _status,
      'role': _role,
      'isBaptized': _isBaptized,
    };
    final nickname = _nicknameCtrl.text.trim();
    if (nickname.isNotEmpty) {
      data['nickname'] = nickname;
    } else if (widget.isEditing) {
      data['nickname'] = null;
    }
    if (_phoneCtrl.text.trim().isNotEmpty) data['phone'] = _phoneCtrl.text.trim();
    if (_emailCtrl.text.trim().isNotEmpty) data['email'] = _emailCtrl.text.trim();
    if (_occupationCtrl.text.trim().isNotEmpty) data['occupation'] = _occupationCtrl.text.trim();
    if (_notesCtrl.text.trim().isNotEmpty) data['notes'] = _notesCtrl.text.trim();
    if (_gender != null) data['gender'] = _gender;
    if (_maritalStatus != null) data['maritalStatus'] = _maritalStatus;
    data['ministryIds'] = _ministryIds.toList();
    if (_ministryIds.isNotEmpty) data['ministryId'] = _ministryIds.first;
    if (_birthDate != null) data['dateOfBirth'] = _birthDate!.toIso8601String();
    if (_baptismDate != null) data['baptismDate'] = _baptismDate!.toIso8601String();
    if (_conversionDate != null) data['conversionDate'] = _conversionDate!.toIso8601String();
    if (_admissionDate != null) data['admissionDate'] = _admissionDate!.toIso8601String();
    if (_admissionType != null) data['admissionType'] = _admissionType;
    if (_baptismChurchCtrl.text.trim().isNotEmpty) data['baptismChurch'] = _baptismChurchCtrl.text.trim();
    if (_linkedUserId != null) {
      data['userId'] = _linkedUserId;
    } else if (widget.isEditing && _originalUserId != null) {
      // Usuário removeu o vínculo manualmente.
      data['userId'] = null;
    }
    // Sem userId no payload: API tenta vincular pelo mesmo e-mail da conta do app.

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

  Future<void> _save({bool forceDuplicate = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = {
        ..._payload(),
        if (forceDuplicate) 'forceDuplicate': true,
      };
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
      final msg = formatError(e);
      final isDuplicate = msg.toLowerCase().contains('duplic') ||
          msg.toLowerCase().contains('conflito') ||
          msg.contains('409');
      if (isDuplicate && !forceDuplicate) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Possível duplicata'),
            content: Text(msg.isNotEmpty
                ? '$msg\n\nDeseja cadastrar mesmo assim?'
                : 'Já existe um membro com dados parecidos. Deseja cadastrar mesmo assim?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cadastrar mesmo assim')),
            ],
          ),
        );
        setState(() => _saving = false);
        if (ok == true) {
          await _save(forceDuplicate: true);
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $msg')));
      setState(() => _saving = false);
    }
  }

  Future<void> _createMinistry(Color t1, Color t2, Color card, Color border) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo ministério'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                hintText: 'Ex: Louvor, Diáconos, Jovens',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Opcional',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008CFF)),
            child: const Text('Criar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    final description = descCtrl.text.trim();
    descCtrl.dispose();

    if (created != true || name.isEmpty || !mounted) return;

    try {
      final ministry = await ref.read(memberRepositoryProvider).createMinistry(
            name: name,
            description: description.isEmpty ? null : description,
          );
      ref.invalidate(ministryListProvider);
      if (!mounted) return;
      setState(() => _ministryIds.add(ministry.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ministério "$name" criado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar ministério: $e')),
      );
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
                  _text('Apelido', _nicknameCtrl, t1, t2, card, border),
                  _text('Telefone', _phoneCtrl, t1, t2, card, border, keyboard: TextInputType.phone),
                  _text('E-mail', _emailCtrl, t1, t2, card, border, keyboard: TextInputType.emailAddress),
                  if (_usersLoaded && _appUsers.isNotEmpty)
                    _dropdown<String?>(
                      'Conta do app (para confirmar escalas)',
                      _linkedUserId != null && _appUsers.any((u) => u.id == _linkedUserId)
                          ? _linkedUserId
                          : null,
                      [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Nenhuma / vincular pelo e-mail'),
                        ),
                        ..._appUsers.map(
                          (u) => DropdownMenuItem<String?>(
                            value: u.id,
                            child: Text('${u.name} (${u.email})', overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      (v) => setState(() => _linkedUserId = v),
                      t1, t2, card, border,
                    )
                  else if (_usersLoaded)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _linkedUserId != null
                            ? 'Conta do app vinculada. Se o e-mail do membro for o mesmo do login, a confirmação nas escalas funciona automaticamente.'
                            : 'Dica: use o mesmo e-mail da conta do app para vincular e permitir confirmação nas escalas.',
                        style: TextStyle(color: t2, fontSize: 12),
                      ),
                    ),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ministérios', style: TextStyle(color: t2, fontSize: 13)),
                            const SizedBox(height: 6),
                            if (ministries.isEmpty)
                              Text('Nenhum ministério cadastrado', style: TextStyle(color: t2))
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: ministries.map((m) {
                                  final selected = _ministryIds.contains(m.id);
                                  return FilterChip(
                                    label: Text(m.name),
                                    selected: selected,
                                    onSelected: (value) {
                                      setState(() {
                                        if (value) {
                                          _ministryIds.add(m.id);
                                        } else {
                                          _ministryIds.remove(m.id);
                                        }
                                      });
                                    },
                                    selectedColor: const Color(0xFF008CFF).withValues(alpha: 0.2),
                                    checkmarkColor: const Color(0xFF008CFF),
                                    labelStyle: TextStyle(
                                      color: selected ? const Color(0xFF008CFF) : t1,
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                    backgroundColor: card,
                                    side: BorderSide(color: selected ? const Color(0xFF008CFF) : border),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Novo ministério',
                        onPressed: () => _createMinistry(t1, t2, card, border),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF008CFF).withValues(alpha: 0.1),
                          foregroundColor: const Color(0xFF008CFF),
                        ),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _text('Observações', _notesCtrl, t1, t2, card, border, maxLines: 3),
                  const SizedBox(height: 20),
                  _section('Endereço', t1),
                  _cepField(t1, t2, card, border),
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

  Widget _cepField(Color t1, Color t2, Color card, Color border) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CEP', style: TextStyle(color: t2, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: TextFormField(
              controller: _zipCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
                LengthLimitingTextInputFormatter(9),
              ],
              onChanged: _onCepChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                hintText: '00000-000',
                hintStyle: TextStyle(color: t2.withValues(alpha: 0.6)),
                suffixIcon: _lookingUpCep
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Buscar CEP',
                        onPressed: _lookingUpCep
                            ? null
                            : () => _onCepChanged(_zipCtrl.text),
                        icon: Icon(Icons.search_rounded, color: t2),
                      ),
              ),
              style: TextStyle(color: t1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Digite o CEP para preencher rua, bairro, cidade e UF automaticamente',
              style: TextStyle(color: t2, fontSize: 12),
            ),
          ),
        ],
      ),
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
