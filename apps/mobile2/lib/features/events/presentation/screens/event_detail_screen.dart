import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  final String id;
  const EventDetailScreen({super.key, required this.id});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: const Color(0xFF008CFF),
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('←', style: TextStyle(fontSize: 20, color: Colors.white)),
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => context.push('/calendar/${widget.id}/edit'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF008CFF), Color(0xFF0066CC)],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(child: Text('📅', style: TextStyle(fontSize: 28))),
                        ),
                        const SizedBox(height: 12),
                        Text('Culto', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Evento Exemplo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: t1)),
                    const SizedBox(height: 16),
                    _infoRow('📅', DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR').format(DateTime.now()), t2),
                    const SizedBox(height: 12),
                    _infoRow('⏰', '19:00', t2),
                    const SizedBox(height: 12),
                    _infoRow('📍', 'Igreja', t2),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Participantes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t1)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _avatar('AB'),
                              const SizedBox(width: -6),
                              _avatar('CD'),
                              const SizedBox(width: -6),
                              _avatar('EF'),
                              const SizedBox(width: 8),
                              Text('+5', style: TextStyle(fontSize: 14, color: t2)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF008CFF)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('Confirmar Presença',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF008CFF))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Descrição', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t1)),
                    const SizedBox(height: 8),
                    Text('Detalhes do evento...',
                        style: TextStyle(fontSize: 15, color: t2, height: 1.5)),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String icon, String text, Color t2) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 15, color: t2)),
      ],
    );
  }

  Widget _avatar(String initials) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF008CFF).withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF008CFF))),
      ),
    );
  }
}
