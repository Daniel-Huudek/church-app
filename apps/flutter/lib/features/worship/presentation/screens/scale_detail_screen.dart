import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/offline/offline_guard.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../domain/worship_models.dart';
import '../../../events/domain/event_model.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../providers/worship_provider.dart';

class ScaleDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ScaleDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ScaleDetailScreen> createState() => _ScaleDetailScreenState();
}

class _ScaleDetailScreenState extends ConsumerState<ScaleDetailScreen> {
  WorshipEvent? _worshipEvent;
  EventModel? _event;
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final worshipRepo = ref.read(worshipRepositoryProvider);
      final eventRepo = ref.read(eventRepositoryProvider);

      final cached = worshipRepo.peekWorshipEventCache(widget.id);
      if (cached != null && mounted) {
        setState(() {
          _worshipEvent = cached;
          _event = eventRepo.peekDetailCache(cached.eventId);
          _loading = false;
        });
      }

      final result = await worshipRepo.getWorshipEvent(widget.id);
      final we = result.data;
      EventModel? ev;
      try {
        ev = (await eventRepo.getById(we.eventId)).data;
      } catch (_) {
        ev = eventRepo.peekDetailCache(we.eventId);
      }
      List<Map<String, dynamic>> users = [];
      try {
        final usersResponse = await ref.read(apiClientProvider).get('/users');
        final usersData = ((usersResponse.data as Map)['data']);
        if (usersData is List) {
          users = usersData.cast<Map<String, dynamic>>();
        }
      } catch (_) {}
      if (mounted) {
        setState(() {
          _worshipEvent = we;
          _event = ev;
          _users = users;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && _worshipEvent == null) setState(() => _loading = false);
    }
  }

  Future<void> _confirmPresence(WorshipEventMusician musician, String status) async {
    try {
      final outcome = await ref.read(worshipRepositoryProvider).confirmMusician(
            widget.id,
            musician.memberId,
            status: status,
          );
      if (mounted) {
        final we = _worshipEvent;
        if (we != null) {
          final updated = we.musicians?.map<WorshipEventMusician>((m) {
            if (m.memberId == musician.memberId) {
              return WorshipEventMusician(
                id: m.id, memberId: m.memberId, instrument: m.instrument,
                role: m.role, isConfirmed: status == 'confirmado', isSubstituted: status == 'indisponivel',
              );
            }
            return m;
          }).toList();
          setState(() {
            _worshipEvent = WorshipEvent(
              id: we.id, eventId: we.eventId, playlistId: we.playlistId,
              notes: we.notes, estimatedTime: we.estimatedTime,
              createdAt: we.createdAt, updatedAt: we.updatedAt,
              songs: we.songs, musicians: updated, playlist: we.playlist,
            );
          });
        }
        if (outcome.queued) {
          notifyMutationQueueChanged(ref);
          showQueuedSyncSnackBar(context);
        }
      }
    } catch (_) {}
  }

  Future<void> _declinePresence(WorshipEventMusician musician) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Não estará disponível?'),
        content: const Text('Sua ausência será registrada. Outro músico poderá ser chamado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, elevation: 0),
            child: const Text('Confirmar Ausência'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final outcome = await ref.read(worshipRepositoryProvider).confirmMusician(
            widget.id,
            musician.memberId,
            status: 'indisponivel',
          );
      if (mounted) {
        final we = _worshipEvent;
        if (we != null) {
          final updated = we.musicians?.map<WorshipEventMusician>((m) {
            if (m.memberId == musician.memberId) {
              return WorshipEventMusician(
                id: m.id, memberId: m.memberId,
                instrument: m.instrument, role: m.role,
                isConfirmed: false, isSubstituted: true,
              );
            }
            return m;
          }).toList();
          setState(() {
            _worshipEvent = WorshipEvent(
              id: we.id, eventId: we.eventId, playlistId: we.playlistId,
              notes: we.notes, estimatedTime: we.estimatedTime,
              createdAt: we.createdAt, updatedAt: we.updatedAt,
              songs: we.songs, musicians: updated, playlist: we.playlist,
            );
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(outcome.queued
                ? 'Ausência salva offline — sincroniza depois'
                : 'Ausência registrada'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
        if (outcome.queued) {
          notifyMutationQueueChanged(ref);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final we = _worshipEvent;
    final ev = _event;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF008CFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF008CFF), size: 24),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          ev?.title ?? 'Escala',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827)),
        ),
        actions: [
          if (ref.read(authProvider).user?.hasAnyRole(['ADMINISTRADOR', 'PASTOR', 'LIDER', 'LIDER_LOUVOR']) == true)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF008CFF), size: 22),
                onPressed: () async {
                  await context.push('/worship/scale/${widget.id}/edit');
                  if (mounted) _load();
                },
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : we == null
              ? Center(child: Text('Escala não encontrada', style: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))))
              : _buildContent(isDark, we, ev),
    );
  }

  Widget _buildContent(bool isDark, WorshipEvent we, EventModel? ev) {
    final songs = we.songs ?? [];
    final musicians = we.musicians ?? [];
    final currentUserId = ref.read(authProvider).user?.id;
    final title = ev?.title ?? 'Evento';
    final date = ev?.date ?? we.createdAt;
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark, title, day, month, year, we),
          const SizedBox(height: 24),
          if (songs.isNotEmpty) ...[
            _buildSectionTitle(isDark, 'Músicas (${songs.length})', Icons.music_note_rounded),
            const SizedBox(height: 12),
            ...songs.asMap().entries.map((e) => Padding(
              padding: EdgeInsets.only(top: e.key > 0 ? 10 : 0),
              child: _buildSongCard(isDark, e.value.song),
            )),
          ],
          if (musicians.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(isDark, 'Músicos (${musicians.length})', Icons.people_rounded),
            const SizedBox(height: 12),
            ...musicians.asMap().entries.map((e) => Padding(
              padding: EdgeInsets.only(top: e.key > 0 ? 10 : 0),
              child: _buildMusicianCard(isDark, e.value, currentUserId),
            )),
          ],
          if (we.notes != null && we.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(isDark, 'Observações', Icons.edit_note_rounded),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161622) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFF3F4F6)),
              ),
              child: Text(we.notes!,
                style: TextStyle(fontSize: 14, height: 1.5,
                  color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, String title, String day, String month, int year, WorshipEvent we) {
    final songs = we.songs ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF008CFF), Color(0xFF0066CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF008CFF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$day $month $year',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.music_note_rounded, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text('${songs.length} músicas',
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF008CFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF008CFF)),
        ),
        const SizedBox(width: 10),
        Text(title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827))),
      ],
    );
  }

  Widget _buildSongCard(bool isDark, Song song) {
    return GestureDetector(
      onTap: () => context.push('/worship/songs/${song.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161622) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.music_note_rounded, color: Color(0xFF008CFF), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF111827))),
                  if (song.artist != null) ...[
                    const SizedBox(height: 3),
                    Text(song.artist!,
                      style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
                  ],
                ],
              ),
            ),
            if (song.key != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(song.key!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF008CFF))),
              ),
            if (song.youtubeUrl != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(song.youtubeUrl!)),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFEF4444), size: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMusicianCard(bool isDark, WorshipEventMusician musician, String? currentUserId) {
    final isCurrentUser = musician.memberId == currentUserId;
    final userData = _users.where((u) => u['id'] == musician.memberId).toList();
    final name = userData.isNotEmpty ? (userData.first['name'] as String? ?? '') : musician.memberId;
    final email = userData.isNotEmpty ? (userData.first['email'] as String? ?? '') : '';
    final avatarUrl = userData.isNotEmpty ? (userData.first['avatar'] as String?) : null;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: avatarUrl != null
                      ? Colors.transparent
                      : (musician.isSubstituted
                          ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                          : musician.isConfirmed
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                        child: avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(imageUrl: '${avatarUrl}?v=0', width: 44, height: 44, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _initialsCircle(initial, musician.isConfirmed, isSubstituted: musician.isSubstituted),
                          placeholder: (_, __) => _initialsCircle(initial, musician.isConfirmed, isSubstituted: musician.isSubstituted)),
                      )
                    : _initialsCircle(initial, musician.isConfirmed, isSubstituted: musician.isSubstituted),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF111827))),
                    if (musician.instrument != null) ...[
                      const SizedBox(height: 3),
                      Text(musician.instrument!,
                        style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
                    ],
                    const SizedBox(height: 3),
                    Text(email,
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: musician.isSubstituted
                      ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                      : musician.isConfirmed
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  musician.isSubstituted
                      ? 'Indisponível'
                      : musician.isConfirmed
                          ? 'Confirmado'
                          : 'Pendente',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: musician.isSubstituted
                        ? const Color(0xFFEF4444)
                        : musician.isConfirmed
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          if (isCurrentUser) ...[
            const SizedBox(height: 10),
            if (!musician.isConfirmed && !musician.isSubstituted)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirmPresence(musician, 'confirmado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Confirmar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _declinePresence(musician),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Não disponível', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            if (musician.isConfirmed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _confirmPresence(musician, 'pendente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Cancelar Confirmação', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            if (musician.isSubstituted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _confirmPresence(musician, 'pendente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Disponibilizar novamente', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _initialsCircle(String initial, bool isConfirmed, {bool isSubstituted = false}) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: isSubstituted
            ? const Color(0xFFEF4444).withValues(alpha: 0.1)
            : isConfirmed
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(initial,
        style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: isSubstituted
              ? const Color(0xFFEF4444)
              : isConfirmed
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
        ),
      ),
    );
  }
}
