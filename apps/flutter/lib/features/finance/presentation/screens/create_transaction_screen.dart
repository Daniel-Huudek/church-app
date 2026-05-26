import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/finance_api.dart';
import '../providers/finance_provider.dart';

class CreateTransactionScreen extends ConsumerStatefulWidget {
  final String initialType;
  const CreateTransactionScreen({super.key, this.initialType = 'INCOME'});

  @override
  ConsumerState<CreateTransactionScreen> createState() => _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends ConsumerState<CreateTransactionScreen> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late String _type;
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _descCtrl.text.trim().isNotEmpty &&
      double.tryParse(_amountCtrl.text.replaceAll(',', '.')) != null &&
      !_loading;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _loading = true);
    try {
      final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
      await ref.read(financeApiProvider).createTransaction({
        'type': _type,
        'value': amount,
        'description': _descCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'date': _date.toIso8601String().substring(0, 10),
      });
      ref.invalidate(financeDashboardProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: $e'), backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : Colors.white;
    final t1 = isDark ? AppColors.darkText : AppColors.lightText;
    final t2 = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.close_rounded, size: 22, color: t1),
            ),
          ),
        ),
        title: Text('Nova Transação', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t1)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Tipo: Receita / Despesa
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'INCOME'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 'INCOME' ? const Color(0xFF10B981) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.trending_up_rounded, size: 18,
                            color: _type == 'INCOME' ? Colors.white : const Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text('Receita',
                            style: TextStyle(fontWeight: FontWeight.w600,
                              color: _type == 'INCOME' ? Colors.white : const Color(0xFF10B981))),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'EXPENSE'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 'EXPENSE' ? const Color(0xFFEF4444) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.trending_down_rounded, size: 18,
                            color: _type == 'EXPENSE' ? Colors.white : const Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                          Text('Despesa',
                            style: TextStyle(fontWeight: FontWeight.w600,
                              color: _type == 'EXPENSE' ? Colors.white : const Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Valor
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valor', style: TextStyle(fontSize: 13, color: t2)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: t1),
                  decoration: InputDecoration(
                    prefixText: 'R\$ ',
                    prefixStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: t2),
                    hintText: '0,00',
                    hintStyle: TextStyle(color: t2.withValues(alpha: 0.4), fontSize: 28),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Descrição
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descrição', style: TextStyle(fontSize: 13, color: t2)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtrl,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: 16, color: t1),
                  decoration: InputDecoration(
                    hintText: 'Ex: Dízimo, Oferta, Luz...',
                    hintStyle: TextStyle(color: t2.withValues(alpha: 0.4)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Data
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 20, color: t2),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data', style: TextStyle(fontSize: 13, color: t2)),
                    const SizedBox(height: 2),
                    Text(Formatters.formatDate(_date), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: t1)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      locale: const Locale('pt', 'BR'),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008CFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Alterar', style: TextStyle(color: Color(0xFF008CFF), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Observações
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Observações (opcional)', style: TextStyle(fontSize: 13, color: t2)),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  style: TextStyle(fontSize: 16, color: t1),
                  decoration: InputDecoration(
                    hintText: 'Observações...',
                    hintStyle: TextStyle(color: t2.withValues(alpha: 0.4)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _canSubmit ? _submit : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _type == 'INCOME'
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (_type == 'INCOME' ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.3),
                    blurRadius: 12, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                      _type == 'INCOME' ? 'Adicionar Receita' : 'Adicionar Despesa',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
