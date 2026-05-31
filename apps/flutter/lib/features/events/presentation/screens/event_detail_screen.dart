import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../providers/event_provider.dart';

class EventDetailScreen extends ConsumerWidget {
  final String id;
  const EventDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final state = ref.watch(eventDetailProvider(id));

    if (state.loading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: const Color(0xFF008CFF), foregroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF008CFF),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text('Erro: ${state.error}')),
      );
    }

    final event = state.event!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF008CFF),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => context.push('/calendar/${event.id}/edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Text('📅', style: TextStyle(fontSize: 28))),
              ),
              const SizedBox(height: 12),
              Text(event.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: t1)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(event.type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
              const SizedBox(height: 20),
              Row(children: [
                const Text('📅', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Text(DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR').format(event.date),
                    style: TextStyle(fontSize: 15, color: t2)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Text('⏰', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Text(event.startTime, style: TextStyle(fontSize: 15, color: t2)),
              ]),
              if (event.location != null) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Text('📍', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(event.location!, style: TextStyle(fontSize: 15, color: t2))),
                ]),
              ],
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Participantes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t1)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: Row(
                        children: [
                          _avatar('AB'),
                          _overlapAvatar('CD'),
                          _overlapAvatar('EF'),
                          const SizedBox(width: 12),
                          Text('+${event.participants}', style: TextStyle(fontSize: 14, color: t2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirmar Presença', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              if (event.description != null) ...[
                const SizedBox(height: 24),
                Text('Descrição', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t1)),
                const SizedBox(height: 8),
                Text(event.description!, style: TextStyle(fontSize: 15, color: t2, height: 1.5)),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String initials) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
    );
  }

  Widget _overlapAvatar(String initials) {
    return Transform.translate(
      offset: const Offset(-8, 0),
      child: _avatar(initials),
    );
  }
}
