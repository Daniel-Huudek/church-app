import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/utils/error_helper.dart';
import '../../domain/event_model.dart';
import '../providers/event_provider.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const EventDetailScreen({super.key, required this.id});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _deleting = false;

  String _typeLabel(String type) {
    switch (type) {
      case 'WORSHIP':
        return 'Culto';
      case 'REHEARSAL':
        return 'Ensaio';
      case 'EVENT':
        return 'Evento';
      default:
        return type;
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _deleteEvent(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir evento'),
        content: Text('Tem certeza que deseja excluir "${event.title}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(eventListProvider.notifier).delete(event.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento excluído')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: ${formatError(e)}')),
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
    final user = ref.watch(authProvider).user;
    final canEdit = user?.hasPermission('events_write') == true;
    final canDelete = user?.hasPermission('events_delete') == true;
    final state = ref.watch(eventDetailProvider(widget.id));

    if (state.loading && state.event == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t1),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.event == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t1),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text('Erro: ${state.error}', style: TextStyle(color: t2))),
      );
    }

    final event = state.event!;
    final dateLabel = _capitalize(
      DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR').format(event.date),
    );
    final timeLabel = event.endTime != null && event.endTime!.isNotEmpty
        ? '${event.startTime} – ${event.endTime}'
        : event.startTime;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: t1),
          onPressed: () => context.pop(),
        ),
        title: Text('Evento', style: TextStyle(color: t1, fontWeight: FontWeight.w600)),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF008CFF)),
              onPressed: () async {
                await context.push(AppRoutes.calendarEdit(event.id));
                if (mounted) ref.read(eventDetailProvider(widget.id).notifier).load();
              },
            ),
          if (canDelete)
            IconButton(
              tooltip: 'Excluir',
              icon: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              onPressed: _deleting ? null : () => _deleteEvent(event),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(eventDetailProvider(widget.id).notifier).load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF008CFF), Color(0xFF0066CC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _typeLabel(event.type),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (event.status.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.status,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.calendar_today_rounded, 'Data', dateLabel, t1, t2),
                  const Divider(height: 24),
                  _infoRow(Icons.schedule_rounded, 'Horário', timeLabel, t1, t2),
                  if (event.location != null && event.location!.trim().isNotEmpty) ...[
                    const Divider(height: 24),
                    _infoRow(Icons.place_outlined, 'Local', event.location!, t1, t2),
                  ],
                  if (event.ministryName != null && event.ministryName!.trim().isNotEmpty) ...[
                    const Divider(height: 24),
                    _infoRow(Icons.groups_outlined, 'Ministério', event.ministryName!, t1, t2),
                  ],
                  if (event.organizerName != null && event.organizerName!.trim().isNotEmpty) ...[
                    const Divider(height: 24),
                    _infoRow(Icons.person_outline, 'Organizador', event.organizerName!, t1, t2),
                  ],
                ],
              ),
            ),
            if (event.description != null && event.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Descrição', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t1)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Text(
                  event.description!,
                  style: TextStyle(fontSize: 15, color: t2, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color t1, Color t2) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF008CFF)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: t2)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t1)),
            ],
          ),
        ),
      ],
    );
  }
}
