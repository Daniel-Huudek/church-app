import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../events/data/event_api.dart';
import '../../../events/domain/event_model.dart';
import '../../data/worship_api.dart';
import '../../domain/worship_models.dart';

class CreateScaleScreen extends ConsumerStatefulWidget {
  final String? scaleId;
  const CreateScaleScreen({super.key, this.scaleId});

  @override
  ConsumerState<CreateScaleScreen> createState() => _CreateScaleScreenState();
}

class _CreateScaleScreenState extends ConsumerState<CreateScaleScreen> {
  int _tabIndex = 0;
  bool _saving = false;
  bool _isEditing = false;

  late final WorshipApi _worshipApi;
  late final EventApi _eventApi;

  List<Song> _allSongs = [];
  List<Song> _selectedSongs = [];
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _selectedMusicians = [];
  final Map<String, String> _musicianInstruments = {};
  bool _loading = true;

  static const _instruments = [
    'Guitarra', 'Violão', 'Baixo', 'Teclado', 'Bateria',
    'Vocal', 'Violino', 'Saxofone', 'Percussão', 'Outro',
  ];
  static const _eventTypes = ['WORSHIP', 'EVENT', 'REHEARSAL'];

  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _searchMemberCtrl = TextEditingController();
  String? _eventId;
  DateTime _selectedDate = DateTime.now();
  final _startTimeCtrl = TextEditingController(text: '19:00');
  final _endTimeCtrl = TextEditingController(text: '21:00');
  String _eventType = 'WORSHIP';

  @override
  void initState() {
    super.initState();
    _worshipApi = WorshipApi(ref.read(apiClientProvider));
    _eventApi = EventApi(ref.read(apiClientProvider));
    if (widget.scaleId != null) _isEditing = true;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final songsRes = await _worshipApi.listSongs(limit: 200).catchError((_) => <String, dynamic>{});
      final songsData = (songsRes['data'] as List?) ?? [];
      final songs = songsData.cast<Map<String, dynamic>>().map((s) => Song.fromJson(s)).toList();

      List<Map<String, dynamic>> usersList = [];
      try {
        final usersResponse = await ref.read(apiClientProvider).get('/users');
        final usersData = ((usersResponse.data as Map)['data']);
        if (usersData is List) {
          usersList = usersData.cast<Map<String, dynamic>>();
        }
      } catch (_) {}

      if (_isEditing && widget.scaleId != null) {
        try {
          final weData = await _worshipApi.getWorshipEvent(widget.scaleId!);
          final we = WorshipEvent.fromJson(weData);
          final ev = await _eventApi.getById(we.eventId);

          _titleCtrl.text = ev.title;
          _eventId = ev.id;
          _selectedDate = ev.date;
          _startTimeCtrl.text = ev.startTime;
          _endTimeCtrl.text = ev.endTime ?? '';
          _eventType = ev.type;
          _notesCtrl.text = we.notes ?? '';

          if (we.songs != null) {
            _selectedSongs = we.songs!.map((s) => s.song).toList();
          }
          if (we.musicians != null) {
            for (final m in we.musicians!) {
              final user = usersList.where((u) => u['id'] == m.memberId).toList();
              if (user.isNotEmpty) {
                _selectedMusicians.add(user.first);
                if (m.instrument != null) _musicianInstruments[m.memberId] = m.instrument!;
              }
            }
          }
        } catch (_) {}
      }

      setState(() {
        _allSongs = songs;
        _allUsers = usersList;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erro: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      if (_isEditing && widget.scaleId != null) {
        final event = await _eventApi.update(_eventId!, {
          'title': _titleCtrl.text.trim(),
          'type': _eventType,
          'date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
          'startTime': _startTimeCtrl.text.trim(),
          'endTime': _endTimeCtrl.text.trim(),
        });

        final notes = _notesCtrl.text.trim();
        await _worshipApi.updateWorshipEvent(widget.scaleId!, {
          if (notes.isNotEmpty) 'notes': notes,
        });

        if (_selectedSongs.isNotEmpty) {
          await _worshipApi.reorderWorshipEventSongs(widget.scaleId!, _selectedSongs.map((s) => s.id).toList());
        }
        if (_selectedMusicians.isNotEmpty) {
          final musicians = _selectedMusicians.map((m) => {
            'memberId': m['id'] as String,
            'instrument': _musicianInstruments[m['id'] as String],
          }).toList();
          await _worshipApi.setWorshipEventMusicians(widget.scaleId!, musicians);
        }
      } else {
        final event = await _eventApi.create({
          'title': _titleCtrl.text.trim(),
          'type': _eventType,
          'date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
          'startTime': _startTimeCtrl.text.trim(),
          'endTime': _endTimeCtrl.text.trim(),
        });

        final notes = _notesCtrl.text.trim();
        final weRes = await _worshipApi.createWorshipEvent({
          'eventId': event.id,
          if (notes.isNotEmpty) 'notes': notes,
        });

        final weData = weRes['data'] as Map<String, dynamic>? ?? weRes;
        final worshipEventId = weData['id'] as String;

        if (_selectedSongs.isNotEmpty) {
          await _worshipApi.reorderWorshipEventSongs(worshipEventId, _selectedSongs.map((s) => s.id).toList());
        }
        if (_selectedMusicians.isNotEmpty) {
          final musicians = _selectedMusicians.map((m) => {
            'memberId': m['id'] as String,
            'instrument': _musicianInstruments[m['id'] as String],
          }).toList();
          await _worshipApi.setWorshipEventMusicians(worshipEventId, musicians);
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      debugPrint('Erro ao salvar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _tabItem(String label, IconData icon, IconData activeIcon, int index) {
    final focused = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: focused ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                focused ? activeIcon : icon,
                size: 16,
                color: focused ? const Color(0xFF008CFF) : Colors.white,
              ),
              if (focused) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: focused ? const Color(0xFF008CFF) : Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    _searchMemberCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  Widget _field(String label, Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _inputBox(Widget child, {double? height}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF008CFF), size: 28),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Nova Escala',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF008CFF)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF008CFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _tabItem('Detalhes', Icons.info_outline, Icons.info, 0),
                  _tabItem('Músicas', Icons.music_note_outlined, Icons.music_note, 1),
                  _tabItem('Participantes', Icons.people_outline, Icons.people, 2),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : IndexedStack(
                      index: _tabIndex,
                      children: [
                        _buildDetalhes(isDark),
                        _buildMusicas(isDark),
                        _buildParticipantes(isDark),
                      ],
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008CFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  _saving ? 'Salvando...' : 'Salvar',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalhes(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _field('Título do evento', _inputBox(
            TextField(
              controller: _titleCtrl,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : const Color(0xFF111827)),
              decoration: const InputDecoration(
                hintText: 'Ex: Culto de Domingo',
                border: InputBorder.none,
              ),
            ),
          )),
          _field('Data', _inputBox(
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _selectedDate = d);
              },
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF008CFF)),
                  const SizedBox(width: 10),
                  Text(
                    '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                    style: TextStyle(fontSize: 15, color: isDark ? Colors.white : const Color(0xFF111827)),
                  ),
                ],
              ),
            ),
            height: 48,
          )),
          Row(
            children: [
              Expanded(child: _field('Início', _inputBox(
                TextField(
                  controller: _startTimeCtrl,
                  style: TextStyle(fontSize: 15, color: isDark ? Colors.white : const Color(0xFF111827)),
                  decoration: const InputDecoration(hintText: '19:00', border: InputBorder.none),
                ),
                height: 48,
              ))),
              const SizedBox(width: 12),
              Expanded(child: _field('Fim', _inputBox(
                TextField(
                  controller: _endTimeCtrl,
                  style: TextStyle(fontSize: 15, color: isDark ? Colors.white : const Color(0xFF111827)),
                  decoration: const InputDecoration(hintText: '21:00', border: InputBorder.none),
                ),
                height: 48,
              ))),
            ],
          ),
          _field('Tipo', Row(
            children: _eventTypes.map((t) {
              final selected = _eventType == t;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: t == _eventTypes.first ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _eventType = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF008CFF) : (isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF9FAFB)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? const Color(0xFF008CFF) : (isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Text(
                        t == 'WORSHIP' ? 'Culto' : t == 'EVENT' ? 'Evento' : 'Ensaio',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : (isDark ? Colors.white : const Color(0xFF111827)),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          )),
          _field('Observações', _inputBox(
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : const Color(0xFF111827)),
              decoration: const InputDecoration(hintText: 'Observações...', border: InputBorder.none),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMusicas(bool isDark) {
    final query = _searchCtrl.text.toLowerCase();
    final filtered = query.isEmpty
        ? _allSongs
        : _allSongs.where((s) =>
            s.title.toLowerCase().contains(query) ||
            (s.artist?.toLowerCase().contains(query) ?? false)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: 'Buscar músicas...',
              hintStyle: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
              prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('${_selectedSongs.length} selecionadas',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF008CFF))),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('Nenhuma música encontrada',
                  style: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))))
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final song = filtered[i];
                    final selected = _selectedSongs.any((s) => s.id == song.id);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF008CFF) : const Color(0xFF008CFF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(selected ? Icons.check_rounded : Icons.music_note_rounded,
                          color: selected ? Colors.white : const Color(0xFF008CFF), size: 20),
                      ),
                      title: Text(song.title,
                        style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827))),
                      subtitle: song.artist != null
                          ? Text(song.artist!, style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)))
                          : null,
                      trailing: selected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF008CFF), size: 22) : null,
                      onTap: () => setState(() {
                        if (selected) { _selectedSongs.removeWhere((s) => s.id == song.id); }
                        else { _selectedSongs.add(song); }
                      }),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildParticipantes(bool isDark) {
    final allowedRoles = ['ADMINISTRADOR', 'PASTOR', 'LIDER', 'LIDER_LOUVOR', 'LOUVOR'];
    final eligibleUsers = _allUsers.where((u) => allowedRoles.contains(u['role'] as String? ?? '')).toList();
    final query = _searchMemberCtrl.text.toLowerCase();
    final filtered = query.isEmpty
        ? eligibleUsers
        : eligibleUsers.where((u) {
            final name = (u['name'] as String? ?? '').toLowerCase();
            final email = (u['email'] as String? ?? '').toLowerCase();
            return name.contains(query) || email.contains(query);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _searchMemberCtrl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: 'Buscar participantes...',
              hintStyle: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
              prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('${_selectedMusicians.length} selecionados',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF008CFF))),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    query.isEmpty ? 'Nenhum usuário com permissão' : 'Nenhum participante encontrado',
                    style: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final user = filtered[i];
                    final userId = user['id'] as String;
                    final name = user['name'] as String? ?? '';
                    final email = user['email'] as String?;
                    final role = user['role'] as String? ?? '';
                    final selected = _selectedMusicians.any((m) => m['id'] == userId);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF008CFF) : const Color(0xFF008CFF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(selected ? Icons.check_rounded : Icons.person_rounded,
                          color: selected ? Colors.white : const Color(0xFF008CFF), size: 20),
                      ),
                      title: Row(children: [
                        Flexible(child: Text(name, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827)))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(role,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF008CFF))),
                        ),
                      ]),
                      subtitle: selected
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _musicianInstruments[userId],
                                    isExpanded: true,
                                    hint: Text('Selecionar instrumento',
                                      style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
                                    items: _instruments.map((inst) => DropdownMenuItem(
                                      value: inst,
                                      child: Text(inst, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827))),
                                    )).toList(),
                                    onChanged: (v) => setState(() { if (v != null) _musicianInstruments[userId] = v; }),
                                  ),
                                ),
                              ),
                            )
                          : (email != null
                              ? Text(email, style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)))
                              : null),
                      trailing: selected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF008CFF), size: 22) : null,
                      onTap: () => setState(() {
                        if (selected) {
                          _selectedMusicians.removeWhere((m) => m['id'] == userId);
                          _musicianInstruments.remove(userId);
                        } else {
                          _selectedMusicians.add(user);
                        }
                      }),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
