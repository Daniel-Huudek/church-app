import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/utils/error_helper.dart';
import '../../../../shared/widgets/app_avatar.dart';
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
  String? _avatarUrl;
  int _tabIndex = 0;

  static const _statuses = ['ATIVO', 'INATIVO', 'AFASTADO', 'TRANSFERIDO'];
  static const _roles = ['MEMBRO', 'DIACONO', 'PRESBITERO', 'PASTOR'];
  static const _genders = ['Masculino', 'Feminino', 'Outro'];
  static const _marital = [
    'Solteiro(a)',
    'Casado(a)',
    'Divorciado(a)',
    'Viúvo(a)'
  ];
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
      _nameCtrl,
      _nicknameCtrl,
      _phoneCtrl,
      _emailCtrl,
      _occupationCtrl,
      _notesCtrl,
      _baptismChurchCtrl,
      _zipCtrl,
      _streetCtrl,
      _numberCtrl,
      _complementCtrl,
      _neighborhoodCtrl,
      _cityCtrl,
      _stateCtrl,
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
      final result =
          await ref.read(memberRepositoryProvider).getById(widget.memberId!);
      _fill(result.data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao carregar: $e')));
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
    _avatarUrl = member.avatar;
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
          : (member.ministryId != null
              ? [member.ministryId!]
              : const <String>[]));
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

  Future<void> _pickDate(
      {required DateTime? current,
      required ValueChanged<DateTime?> onPicked}) async {
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
      final address =
          await ref.read(cepLookupServiceProvider).lookup(requested);
      if (!mounted || address == null) return;
      _lastLookedUpCep = requested;
      setState(() {
        _zipCtrl.text = address.zipCode;
        if (address.street.isNotEmpty) _streetCtrl.text = address.street;
        if (address.neighborhood.isNotEmpty)
          _neighborhoodCtrl.text = address.neighborhood;
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
        const SnackBar(
            content:
                Text('Não foi possível consultar o CEP. Tente novamente.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Não foi possível consultar o CEP. Tente novamente.')),
      );
    } finally {
      if (mounted) {
        setState(() => _lookingUpCep = false);
        final current = normalizeCep(_zipCtrl.text);
        // Só busca de novo se o usuário alterou o CEP durante a consulta.
        if (current.length == 8 &&
            current != requested &&
            current != _lastLookedUpCep) {
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
    if (_phoneCtrl.text.trim().isNotEmpty)
      data['phone'] = _phoneCtrl.text.trim();
    if (_emailCtrl.text.trim().isNotEmpty)
      data['email'] = _emailCtrl.text.trim();
    if (_occupationCtrl.text.trim().isNotEmpty)
      data['occupation'] = _occupationCtrl.text.trim();
    if (_notesCtrl.text.trim().isNotEmpty)
      data['notes'] = _notesCtrl.text.trim();
    if (_gender != null) data['gender'] = _gender;
    if (_maritalStatus != null) data['maritalStatus'] = _maritalStatus;
    data['ministryIds'] = _ministryIds.toList();
    if (_ministryIds.isNotEmpty) data['ministryId'] = _ministryIds.first;
    if (_birthDate != null) data['dateOfBirth'] = _birthDate!.toIso8601String();
    if (_baptismDate != null)
      data['baptismDate'] = _baptismDate!.toIso8601String();
    if (_conversionDate != null)
      data['conversionDate'] = _conversionDate!.toIso8601String();
    if (_admissionDate != null)
      data['admissionDate'] = _admissionDate!.toIso8601String();
    if (_admissionType != null) data['admissionType'] = _admissionType;
    if (_baptismChurchCtrl.text.trim().isNotEmpty)
      data['baptismChurch'] = _baptismChurchCtrl.text.trim();
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
        'number':
            _numberCtrl.text.trim().isEmpty ? null : _numberCtrl.text.trim(),
        'complement': _complementCtrl.text.trim().isEmpty
            ? null
            : _complementCtrl.text.trim(),
        'neighborhood': _neighborhoodCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim().toUpperCase(),
        'zipCode': _zipCtrl.text.trim(),
      };
    }
    return data;
  }

  Future<void> _save({bool forceDuplicate = false}) async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _tabIndex = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome completo')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = {
        ..._payload(),
        if (forceDuplicate) 'forceDuplicate': true,
      };
      if (widget.isEditing) {
        await ref
            .read(memberListProvider.notifier)
            .update(widget.memberId!, payload);
        if (!mounted) return;
        ref.invalidate(memberDetailProvider(widget.memberId!));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Membro atualizado')));
        context.pop();
      } else {
        final created =
            await ref.read(memberListProvider.notifier).create(payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Membro cadastrado')));
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
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Cadastrar mesmo assim')),
            ],
          ),
        );
        setState(() => _saving = false);
        if (ok == true) {
          await _save(forceDuplicate: true);
        }
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $msg')));
      setState(() => _saving = false);
    }
  }

  Future<void> _createMinistry(
      Color t1, Color t2, Color card, Color border) async {
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
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008CFF)),
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
    final ministries =
        ref.watch(ministryListProvider).valueOrNull ?? const <MinistryModel>[];
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F6F8);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF17233B);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF667085);
    final border = isDark ? const Color(0xFF2D2D44) : const Color(0xFFE1E5EA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.close_rounded, color: t1),
        ),
        title: Text(
          widget.isEditing ? 'Editar membro' : 'Novo membro',
          style: TextStyle(color: t1, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Salvar',
            onPressed: _saving || _loading ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF008CFF),
                    size: 28,
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _profileHeader(t1, t2, card, border),
                  const SizedBox(height: 18),
                  _professionalTabs(t2, card, border),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      key: ValueKey(_tabIndex),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: border),
                      ),
                      child: _tabContent(
                        ministries,
                        t1,
                        t2,
                        card,
                        border,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: bg,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(
            children: [
              if (_tabIndex > 0) ...[
                OutlinedButton(
                  onPressed: () => setState(() => _tabIndex--),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF008CFF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving || _loading
                      ? null
                      : _tabIndex < 3
                          ? () => setState(() => _tabIndex++)
                          : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008CFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _saving
                        ? 'Salvando...'
                        : _tabIndex < 3
                            ? 'Próximo'
                            : widget.isEditing
                                ? 'Salvar alterações'
                                : 'Cadastrar membro',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get _profileCompletion {
    final checks = <bool>[
      _nameCtrl.text.trim().isNotEmpty,
      _phoneCtrl.text.trim().isNotEmpty,
      _emailCtrl.text.trim().isNotEmpty,
      _birthDate != null,
      _gender != null,
      _maritalStatus != null,
      _occupationCtrl.text.trim().isNotEmpty,
      _ministryIds.isNotEmpty,
      _cityCtrl.text.trim().isNotEmpty,
      _zipCtrl.text.trim().isNotEmpty,
    ];
    return (checks.where((item) => item).length / checks.length * 100).round();
  }

  Widget _profileHeader(Color t1, Color t2, Color card, Color border) {
    final displayName =
        _nameCtrl.text.trim().isEmpty ? 'Novo membro' : _nameCtrl.text.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          AppAvatar(
            name: displayName,
            imageUrl: _avatarUrl,
            authenticated: _avatarUrl != null,
            size: 64,
            showBorder: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t1,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEditing
                      ? 'Perfil $_profileCompletion% completo'
                      : 'Preencha os dados do novo membro',
                  style: TextStyle(color: t2, fontSize: 12),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _profileCompletion / 100,
                    minHeight: 6,
                    backgroundColor: border,
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFF008CFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _professionalTabs(Color t2, Color card, Color border) {
    const tabs = [
      ('Pessoal', Icons.person_outline_rounded),
      ('Contato', Icons.phone_outlined),
      ('Igreja', Icons.church_outlined),
      ('Endereço', Icons.location_on_outlined),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final selected = _tabIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _tabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      selected ? const Color(0xFF008CFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      tabs[index].$2,
                      size: 16,
                      color: selected ? Colors.white : t2,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[index].$1,
                      style: TextStyle(
                        color: selected ? Colors.white : t2,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _tabContent(
    List<MinistryModel> ministries,
    Color t1,
    Color t2,
    Color card,
    Color border,
  ) {
    switch (_tabIndex) {
      case 0:
        return _personalTab(t1, t2, card, border);
      case 1:
        return _contactTab(t1, t2, card, border);
      case 2:
        return _churchTab(ministries, t1, t2, card, border);
      default:
        return _addressTab(t1, t2, card, border);
    }
  }

  Widget _personalTab(Color t1, Color t2, Color card, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Informações pessoais', t1),
        _text(
          'Nome completo *',
          _nameCtrl,
          t1,
          t2,
          card,
          border,
          requiredField: true,
        ),
        _text('Apelido', _nicknameCtrl, t1, t2, card, border),
        _dateField(
          'Data de nascimento',
          _birthDate,
          () => _pickDate(
            current: _birthDate,
            onPicked: (date) => setState(() => _birthDate = date),
          ),
          t1,
          t2,
          card,
          border,
        ),
        _dropdown<String>(
          'Gênero',
          _genders.contains(_gender) ? _gender : null,
          _genders
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          (value) => setState(() => _gender = value),
          t1,
          t2,
          card,
          border,
        ),
        _dropdown<String>(
          'Estado civil',
          _marital.contains(_maritalStatus) ? _maritalStatus : null,
          _marital
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          (value) => setState(() => _maritalStatus = value),
          t1,
          t2,
          card,
          border,
        ),
        _text('Profissão', _occupationCtrl, t1, t2, card, border),
      ],
    );
  }

  Widget _contactTab(Color t1, Color t2, Color card, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Contato e acesso', t1),
        _text(
          'Telefone',
          _phoneCtrl,
          t1,
          t2,
          card,
          border,
          keyboard: TextInputType.phone,
        ),
        _text(
          'E-mail',
          _emailCtrl,
          t1,
          t2,
          card,
          border,
          keyboard: TextInputType.emailAddress,
        ),
        if (_usersLoaded && _appUsers.isNotEmpty)
          _dropdown<String?>(
            'Conta do app (para confirmar escalas)',
            _linkedUserId != null &&
                    _appUsers.any((user) => user.id == _linkedUserId)
                ? _linkedUserId
                : null,
            [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Nenhuma / vincular pelo e-mail'),
              ),
              ..._appUsers.map(
                (user) => DropdownMenuItem<String?>(
                  value: user.id,
                  child: Text(
                    '${user.name} (${user.email})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            (value) => setState(() => _linkedUserId = value),
            t1,
            t2,
            card,
            border,
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF008CFF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF008CFF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Usar o mesmo e-mail da conta vincula o membro e permite confirmar escalas.',
                  style: TextStyle(color: t2, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _churchTab(
    List<MinistryModel> ministries,
    Color t1,
    Color t2,
    Color card,
    Color border,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Vida na igreja', t1),
        Row(
          children: [
            Expanded(
              child: _dropdown<String>(
                'Status',
                _status,
                _statuses
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                (value) => setState(() => _status = value ?? 'ATIVO'),
                t1,
                t2,
                card,
                border,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdown<String>(
                'Cargo',
                _role,
                _roles
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                (value) => setState(() => _role = value ?? 'MEMBRO'),
                t1,
                t2,
                card,
                border,
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: SwitchListTile(
            title: Text(
              'Membro batizado',
              style: TextStyle(color: t1, fontWeight: FontWeight.w600),
            ),
            value: _isBaptized,
            activeColor: const Color(0xFF008CFF),
            onChanged: (value) => setState(() => _isBaptized = value),
          ),
        ),
        if (_isBaptized) ...[
          _dateField(
            'Data do batismo',
            _baptismDate,
            () => _pickDate(
              current: _baptismDate,
              onPicked: (date) => setState(() => _baptismDate = date),
            ),
            t1,
            t2,
            card,
            border,
          ),
          _text(
            'Igreja do batismo',
            _baptismChurchCtrl,
            t1,
            t2,
            card,
            border,
          ),
        ],
        _dateField(
          'Data de conversão',
          _conversionDate,
          () => _pickDate(
            current: _conversionDate,
            onPicked: (date) => setState(() => _conversionDate = date),
          ),
          t1,
          t2,
          card,
          border,
        ),
        _dateField(
          'Data de admissão',
          _admissionDate,
          () => _pickDate(
            current: _admissionDate,
            onPicked: (date) => setState(() => _admissionDate = date),
          ),
          t1,
          t2,
          card,
          border,
        ),
        _dropdown<String>(
          'Tipo de admissão',
          _admissionTypes.any((item) => item.$1 == _admissionType)
              ? _admissionType
              : null,
          _admissionTypes
              .map(
                (item) =>
                    DropdownMenuItem(value: item.$1, child: Text(item.$2)),
              )
              .toList(),
          (value) => setState(() => _admissionType = value),
          t1,
          t2,
          card,
          border,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ministérios',
                    style: TextStyle(color: t2, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (ministries.isEmpty)
                    Text(
                      'Nenhum ministério cadastrado',
                      style: TextStyle(color: t2),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ministries.map((ministry) {
                        final selected = _ministryIds.contains(ministry.id);
                        return FilterChip(
                          label: Text(ministry.name),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _ministryIds.add(ministry.id);
                              } else {
                                _ministryIds.remove(ministry.id);
                              }
                            });
                          },
                          selectedColor: const Color(
                            0xFF008CFF,
                          ).withValues(alpha: 0.16),
                          checkmarkColor: const Color(0xFF008CFF),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Novo ministério',
              onPressed: () => _createMinistry(t1, t2, card, border),
              icon: const Icon(
                Icons.add_circle_rounded,
                color: Color(0xFF008CFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _text(
          'Observações',
          _notesCtrl,
          t1,
          t2,
          card,
          border,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _addressTab(Color t1, Color t2, Color card, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Endereço', t1),
        _cepField(t1, t2, card, border),
        _text('Rua', _streetCtrl, t1, t2, card, border),
        Row(
          children: [
            Expanded(
              child: _text(
                'Número',
                _numberCtrl,
                t1,
                t2,
                card,
                border,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _text(
                'Complemento',
                _complementCtrl,
                t1,
                t2,
                card,
                border,
              ),
            ),
          ],
        ),
        _text('Bairro', _neighborhoodCtrl, t1, t2, card, border),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _text(
                'Cidade',
                _cityCtrl,
                t1,
                t2,
                card,
                border,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _text('UF', _stateCtrl, t1, t2, card, border),
            ),
          ],
        ),
      ],
    );
  }

  Widget _section(String title, Color t1) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(title,
          style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t1)),
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
            decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border)),
            child: TextFormField(
              controller: ctrl,
              keyboardType: keyboard,
              maxLines: maxLines,
              onChanged: (_) => setState(() {}),
              validator: requiredField
                  ? (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obrigatório' : null
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
              decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border)),
              child: Text(value == null ? 'Selecionar' : _fmt(value),
                  style: TextStyle(color: value == null ? t2 : t1)),
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
            decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border)),
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
