import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/prayer_provider.dart';

class CreatePrayerScreen extends ConsumerStatefulWidget {
  const CreatePrayerScreen({super.key});

  @override
  ConsumerState<CreatePrayerScreen> createState() => _CreatePrayerScreenState();
}

class _CreatePrayerScreenState extends ConsumerState<CreatePrayerScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isAnonymous = false;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _titleCtrl.text.trim().isNotEmpty &&
      _contentCtrl.text.trim().isNotEmpty &&
      !_loading;

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;
    setState(() => _loading = true);
    try {
      await ref.read(prayerApiProvider).create({
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'isAnonymous': _isAnonymous,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Pedido enviado com sucesso!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(child: Text('←', style: TextStyle(fontSize: 28))),
                    ),
                  ),
                  const Spacer(),
                  Text('Novo Pedido',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: t1)),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Título',
                            style: TextStyle(fontSize: 14, color: t2)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _titleCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Do que você precisa orar?',
                            hintStyle: TextStyle(color: t2, fontSize: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF008CFF), width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                            isDense: true,
                          ),
                          style: TextStyle(color: t1, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pedido',
                            style: TextStyle(fontSize: 14, color: t2)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _contentCtrl,
                          onChanged: (_) => setState(() {}),
                          maxLines: 4,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: 'Compartilhe os detalhes...',
                            hintStyle: TextStyle(color: t2, fontSize: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF008CFF), width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                          style: TextStyle(color: t1, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pedido anônimo',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: t1)),
                            const SizedBox(height: 2),
                            Text('Seu nome não será exibido',
                                style: TextStyle(fontSize: 12, color: t2)),
                          ],
                        ),
                        Switch(
                          value: _isAnonymous,
                          onChanged: (v) =>
                              setState(() => _isAnonymous = v),
                          activeTrackColor:
                              const Color(0xFF008CFF).withValues(alpha: 0.5),
                          activeColor: const Color(0xFF008CFF),
                          inactiveThumbColor: t2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _canSubmit ? _handleSubmit : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _titleCtrl.text.trim().isNotEmpty &&
                                _contentCtrl.text.trim().isNotEmpty
                            ? const Color(0xFF008CFF)
                            : const Color(0xFF6B7280),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _loading ? 'Enviando...' : 'Enviar Pedido',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
