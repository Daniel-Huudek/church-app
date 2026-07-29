import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Bottom sheet to pick a month that has scales available to copy.
Future<DateTime?> showScaleMonthPicker({
  required BuildContext context,
  required List<DateTime> dates,
  DateTime? initialMonth,
}) async {
  final months = _uniqueMonths(dates);
  if (months.isEmpty) return null;

  final now = DateTime.now();
  final preferred = initialMonth ?? DateTime(now.year, now.month);
  final preferredKey = _monthKey(preferred);
  var selected = months.firstWhere(
    (m) => _monthKey(m) == preferredKey,
    orElse: () => months.first,
  );

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final sheetBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
      final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
      final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
      final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Copiar escala do mês',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: t1,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close_rounded, color: t2),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Selecione o mês que deseja copiar para o WhatsApp',
                        style: TextStyle(fontSize: 13, color: t2),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      itemCount: months.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, index) {
                        final month = months[index];
                        final isSelected = _monthKey(month) == _monthKey(selected);
                        final label = _capitalize(
                          DateFormat('MMMM yyyy', 'pt_BR').format(month),
                        );
                        final count = dates.where((d) =>
                            d.year == month.year && d.month == month.month).length;

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: isSelected,
                          selectedTileColor: const Color(0xFF008CFF).withValues(alpha: 0.12),
                          leading: Icon(
                            Icons.calendar_month_rounded,
                            color: isSelected ? const Color(0xFF008CFF) : t2,
                          ),
                          title: Text(
                            label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF008CFF) : t1,
                            ),
                          ),
                          subtitle: Text(
                            count == 1 ? '1 escala' : '$count escalas',
                            style: TextStyle(fontSize: 12, color: t2),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF008CFF))
                              : null,
                          onTap: () => setModalState(() => selected = month),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(selected),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008CFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Copiar mês',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

List<DateTime> _uniqueMonths(List<DateTime> dates) {
  final map = <String, DateTime>{};
  for (final date in dates) {
    final key = _monthKey(date);
    map.putIfAbsent(key, () => DateTime(date.year, date.month));
  }
  final months = map.values.toList()
    ..sort((a, b) => b.compareTo(a));
  return months;
}

String _monthKey(DateTime date) => '${date.year}-${date.month}';

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
