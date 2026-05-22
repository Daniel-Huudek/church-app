import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../data/worship_api.dart';
import '../../domain/worship_models.dart';
import '../providers/worship_provider.dart';
import '../widgets/song_card.dart';

class WorshipRepertoryScreen extends ConsumerStatefulWidget {
  final String eventId;
  const WorshipRepertoryScreen({super.key, required this.eventId});
  @override ConsumerState<WorshipRepertoryScreen> createState() => _WorshipRepertoryScreenState();
}

class _WorshipRepertoryScreenState extends ConsumerState<WorshipRepertoryScreen> {
  WorshipEvent? _event;
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await ref.read(worshipApiProvider).getWorshipEventByEvent(widget.eventId);
      if (mounted) setState(() {
        _event = r != null ? WorshipEvent.fromJson(r['data'] as Map<String, dynamic>? ?? r) : null;
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Repertório do Culto', style: TextStyle(fontWeight: FontWeight.w600))),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _event == null ? _emptyState(isDark) : _content(isDark),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.music_note_outlined, size: 64, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
      const SizedBox(height: 16),
      Text('Nenhum repertório vinculado', style: TextStyle(fontSize: 16, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))),
      const SizedBox(height: 24),
      ElevatedButton.icon(icon: const Icon(Icons.add_rounded), label: const Text('Criar Repertório'), onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
    ]));
  }

  Widget _content(bool isDark) {
    return SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _header(isDark),
      const SizedBox(height: 20),
      if (_event!.notes != null) _notesCard(isDark),
      if (_event!.songs != null) _songsList(isDark),
      if (_event!.musicians != null && _event!.musicians!.isNotEmpty) _musiciansSection(isDark),
    ]));
  }

  Widget _header(bool isDark) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF6366F1), const Color(0xFF008CFF)]), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.celebration_rounded, color: Colors.white, size: 28), const Spacer(),
          if (_event!.estimatedTime != null)
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Text('${_event!.estimatedTime}min', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
        ]),
        const SizedBox(height: 12),
        Text('Repertório', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text('${_event!.songs?.length ?? 0} músicas', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
      ]),
    );
  }

  Widget _notesCard(bool isDark) {
    return Column(children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.notes_rounded, size: 18, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)), const SizedBox(width: 8),
          Expanded(child: Text(_event!.notes!, style: TextStyle(color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280), fontSize: 13))),
        ]),
      ),
      const SizedBox(height: 16),
    ]);
  }

  Widget _songsList(bool isDark) {
    return Column(children: _event!.songs!.map((s) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('${s.order}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)))),
        const SizedBox(width: 12),
        Expanded(child: SongCard(song: s.song)),
      ]))
    ).toList());
  }

  Widget _musiciansSection(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),
      Text('Equipe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
      const SizedBox(height: 12),
      ..._event!.musicians!.map((m) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E) : Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(m.isConfirmed ? Icons.check_circle_rounded : Icons.pending_rounded, size: 20, color: m.isConfirmed ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Expanded(child: Text('Músico #${m.memberId}', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)))),
          if (m.instrument != null) Text(m.instrument!, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
        ])),
      ).toList(),
    ]);
  }
}
