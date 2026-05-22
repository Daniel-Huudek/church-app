import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final t1 = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final t2 = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

    final sections = [
      ('Geral', [
        ('Idioma', 'Português'),
        ('Notificações', ''),
      ]),
      ('Aparência', [
        ('Tema', isDark ? 'Escuro' : 'Claro'),
      ]),
      ('Conta', [
        ('Alterar Senha', ''),
        ('Exportar Dados', ''),
      ]),
      ('Sobre', [
        ('Versão', '1.0.0'),
        ('Termos de Uso', ''),
        ('Privacidade', ''),
      ]),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('←', style: TextStyle(fontSize: 24)),
          ),
        ),
        title: Text('Configurações',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t1)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 24),
        itemBuilder: (context, i) {
          final title = sections[i].$1;
          final items = sections[i].$2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: t2,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: items.asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    final isLast = idx == items.length - 1;
                    return Column(
                      children: [
                        ListTile(
                          dense: true,
                          onTap: () {},
                          title: Text(item.$1,
                              style: TextStyle(fontSize: 15, color: t1)),
                          trailing: item.$2.isNotEmpty
                              ? Text(item.$2,
                                  style: TextStyle(fontSize: 14, color: t2))
                              : Icon(Icons.chevron_right, color: t2, size: 20),
                        ),
                        if (!isLast)
                          Divider(height: 1, color: border, indent: 16, endIndent: 16),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
