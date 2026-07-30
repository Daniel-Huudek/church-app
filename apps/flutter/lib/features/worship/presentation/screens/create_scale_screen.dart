import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../events/data/event_api.dart';
import '../../../events/domain/event_model.dart';
import '../../../events/presentation/widgets/event_source_section.dart';
import '../../../members/data/member_api.dart';
import '../../../members/domain/member_model.dart';
import '../../../../shared/utils/person_name.dart';
import '../../data/worship_api.dart';
import '../../data/worship_ministry_helper.dart';
import '../../domain/worship_models.dart';
import '../providers/worship_provider.dart';

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
  List<MemberModel> _allMembers = [];
  List<MemberModel> _selectedMusicians = [];
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
  EventLinkMode _eventLinkMode = EventLinkMode.existing;
  List<EventModel> _availableEvents = [];
  Set<String> _eventsWithWorshipScale = {};

  String _datePayload(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _applyEvent(EventModel event) {
    _eventId = event.id;
    _titleCtrl.text = event.title;
    _selectedDate = event.date;
    _startTimeCtrl.text = event.startTime;
    _endTimeCtrl.text = event.endTime ?? '';
    _eventType = event.type;
  }

  void _clearEventFields() {
    _eventId = null;
    _titleCtrl.clear();
    _selectedDate = DateTime.now();
    _startTimeCtrl.text = '19:00';
    _endTimeCtrl.text = '21:00';
    _eventType = 'WORSHIP';
  }

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
      final memberApi = MemberApi(ref.read(apiClientProvider));
      final songsRes = await _worshipApi.listSongs(limit: 200).catchError((_) => <String, dynamic>{});
      final songsData = (songsRes['data'] as List?) ?? [];
      final songs = songsData.cast<Map<String, dynamic>>().map((s) => Song.fromJson(s)).toList();

      List<MemberModel> members = [];
      try {
        final ministry = await WorshipMinistryHelper.ensureMinistry(memberApi);
        members = await memberApi.list(ministryId: ministry.id, limit: 100, status: 'ATIVO');
      } catch (e) {
        debugPrint('Erro ao carregar membros do louvor: $e');
      }

      List<EventModel> events = [];
      Set<String> usedEventIds = {};
      if (!_isEditing) {
        try {
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
          final end = start.add(const Duration(days: 120));
          events = await _eventApi.list(startDate: start, endDate: end);
          events.sort((a, b) => a.date.compareTo(b.date));
        } catch (_) {}

        try {
          final worshipList = await ref.read(worshipRepositoryProvider).listWorshipEvents(limit: 100);
          usedEventIds = worshipList.data.map((e) => e.eventId).toSet();
        } catch (_) {}
      }

      final selected = <MemberModel>[];
      if (_isEditing && widget.scaleId != null) {
        try {
          final weData = await _worshipApi.getWorshipEvent(widget.scaleId!);
          final raw = weData.containsKey('data') && weData['data'] is Map
              ? Map<String, dynamic>.from(weData['data'] as Map)
              : weData;
          final we = WorshipEvent.fromJson(raw);
          final ev = await _eventApi.getById(we.eventId);

          _applyEvent(ev);
          _notesCtrl.text = we.notes ?? '';
          _eventLinkMode = EventLinkMode.existing;

          if (we.songs != null) {
            _selectedSongs = we.songs!.map((s) => s.song).toList();
          }
          if (we.musicians != null) {
            for (final m in we.musicians!) {
              MemberModel? member;
              final byId = members.where((mem) => mem.id == m.memberId).toList();
              if (byId.isNotEmpty) {
                member = byId.first;
              } else {
                // Legacy scales stored userId in memberId — resolve via userId.
                final byUser = members.where((mem) => mem.userId == m.memberId).toList();
                if (byUser.isNotEmpty) {
                  member = byUser.first;
                } else {
                  // Still show already-scheduled people even if ministry changed.
                  try {
                    member = await memberApi.getById(m.memberId);
                  } catch (_) {}
                }
              }
              if (member != null) {
                selected.add(member);
                if (m.instrument != null) _musicianInstruments[member.id] = m.instrument!;
              }
            }
          }
        } catch (_) {}
      } else if (events.isEmpty) {
        _eventLinkMode = EventLinkMode.createNew;
      }

      setState(() {
        _allSongs = songs;
        _allMembers = members;
        _selectedMusicians = selected;
        _availableEvents = events;
        _eventsWithWorshipScale = usedEventIds;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erro: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o título do evento')),
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

    setState(() => _saving = true);
    try {
      String? savedWorshipEventId;
      final musiciansPayload = _selectedMusicians.map((m) {
        final instrument = _musicianInstruments[m.id];
        return <String, dynamic>{
          'memberId': m.id,
          if (instrument != null) 'instrument': instrument,
        };
      }).toList();
      final songIds = _selectedSongs.map((s) => s.id).toList();
      final eventPayload = {
        'title': _titleCtrl.text.trim(),
        'type': _eventType,
        'date': _datePayload(_selectedDate),
        'startTime': _startTimeCtrl.text.trim().isEmpty ? '19:00' : _startTimeCtrl.text.trim(),
        'endTime': _endTimeCtrl.text.trim().isEmpty ? '21:00' : _endTimeCtrl.text.trim(),
      };

      if (_isEditing && widget.scaleId != null) {
        savedWorshipEventId = widget.scaleId;
        await _eventApi.update(_eventId!, eventPayload);

        await _worshipApi.updateWorshipEvent(widget.scaleId!, {
          'notes': _notesCtrl.text.trim(),
        });

        // Always sync songs/musicians so removals are persisted.
        await _worshipApi.reorderWorshipEventSongs(widget.scaleId!, songIds);
        await _worshipApi.setWorshipEventMusicians(widget.scaleId!, musiciansPayload);
      } else {
        late final String linkedEventId;
        if (_eventLinkMode == EventLinkMode.existing) {
          linkedEventId = _eventId!;
          if (_eventsWithWorshipScale.contains(linkedEventId)) {
            throw Exception('Este evento já possui escala de louvor');
          }
          // Keep shared event details in sync for Louvor + Diáconos.
          await _eventApi.update(linkedEventId, eventPayload);
        } else {
          final event = await _eventApi.create(eventPayload);
          linkedEventId = event.id;
        }

        final notes = _notesCtrl.text.trim();
        final weRes = await _worshipApi.createWorshipEvent({
          'eventId': linkedEventId,
          if (notes.isNotEmpty) 'notes': notes,
        });

        final weData = weRes['data'] as Map<String, dynamic>? ?? weRes;
        final worshipEventId = weData['id'] as String;
        savedWorshipEventId = worshipEventId;

        if (songIds.isNotEmpty) {
          await _worshipApi.reorderWorshipEventSongs(worshipEventId, songIds);
        }
        if (musiciansPayload.isNotEmpty) {
          await _worshipApi.setWorshipEventMusicians(worshipEventId, musiciansPayload);
        }
      }

      await ref.read(worshipRepositoryProvider).invalidateWorshipEventCaches(
            id: savedWorshipEventId,
          );

      if (mounted) context.pop(true);
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
          _isEditing ? 'Editar Escala' : 'Nova Escala',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF008CFF)),
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
                  _tabItem('Músicos', Icons.people_outline, Icons.people, 2),
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
          if (!_isEditing) ...[
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
              unavailableEventIds: _eventsWithWorshipScale,
              selectedEventId: _eventId,
              onSelectEvent: (event) => setState(() => _applyEvent(event)),
              unavailableHint: 'Já tem escala de louvor',
            ),
            const SizedBox(height: 16),
          ],
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
          _field(
            _eventLinkMode == EventLinkMode.existing && !_isEditing
                ? 'Observações da escala de louvor'
                : 'Observações',
            _inputBox(
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: TextStyle(fontSize: 15, color: isDark ? Colors.white : const Color(0xFF111827)),
                decoration: const InputDecoration(hintText: 'Observações da escala...', border: InputBorder.none),
              ),
            ),
          ),
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
    final query = _searchMemberCtrl.text.trim().toLowerCase();
    final available = _allMembers.where((m) {
      final selected = _selectedMusicians.any((s) => s.id == m.id);
      if (selected) return false;
      if (query.isEmpty) return true;
      return preferredPersonName(name: m.name, nickname: m.nickname).toLowerCase().contains(query) ||
          m.name.toLowerCase().contains(query) ||
          (m.email?.toLowerCase().contains(query) ?? false);
    }).toList();

    final t1 = isDark ? Colors.white : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final card = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF9FAFB);
    final border = isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB);
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);

    return ListView(
      children: [
        Text(
          'Músicos escalados',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t1),
        ),
        const SizedBox(height: 8),
        if (_selectedMusicians.isEmpty)
          Text('Nenhum músico adicionado ainda.', style: TextStyle(color: t2, fontSize: 13))
        else
          ..._selectedMusicians.asMap().entries.map((entry) {
            final index = entry.key;
            final member = entry.value;
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preferredPersonName(name: member.name, nickname: member.nickname),
                          style: TextStyle(color: t1, fontWeight: FontWeight.w600),
                        ),
                        if (member.email != null) ...[
                          const SizedBox(height: 2),
                          Text(member.email!, style: TextStyle(color: t2, fontSize: 12)),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _musicianInstruments[member.id],
                              isExpanded: true,
                              hint: Text('Selecionar instrumento', style: TextStyle(fontSize: 13, color: t2)),
                              items: _instruments
                                  .map((inst) => DropdownMenuItem(
                                        value: inst,
                                        child: Text(inst, style: TextStyle(fontSize: 13, color: t1)),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _musicianInstruments[member.id] = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _selectedMusicians.removeAt(index);
                      _musicianInstruments.remove(member.id);
                    }),
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 16),
        Text(
          'Adicionar músico do Louvor',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t1),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: TextField(
            controller: _searchMemberCtrl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: t1),
            decoration: InputDecoration(
              hintText: 'Buscar membro...',
              hintStyle: TextStyle(color: t2),
              prefixIcon: Icon(Icons.search_rounded, color: t2),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (available.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _allMembers.isEmpty
                  ? 'Nenhum membro no ministério de Louvor. Cadastre membros nesse ministério.'
                  : (query.isEmpty ? 'Todos os membros do louvor já foram adicionados' : 'Nenhum membro encontrado'),
              style: TextStyle(color: t2, fontSize: 13),
            ),
          )
        else
          ...available.take(20).map((member) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  preferredPersonName(name: member.name, nickname: member.nickname),
                  style: TextStyle(color: t1, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [
                    if (member.ministryName != null && member.ministryName!.isNotEmpty) member.ministryName!,
                    if (member.email != null) member.email!,
                  ].join(' · '),
                  style: TextStyle(color: t2, fontSize: 12),
                ),
                trailing: IconButton(
                  onPressed: () => setState(() {
                    _selectedMusicians.add(member);
                    _musicianInstruments.putIfAbsent(member.id, () => 'Vocal');
                  }),
                  icon: const Icon(Icons.add_circle, color: Color(0xFF008CFF)),
                ),
              )),
      ],
    );
  }
}
