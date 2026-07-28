import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/bible_models.dart';

class BibleHomeScreen extends StatefulWidget {
  const BibleHomeScreen({super.key});

  @override
  State<BibleHomeScreen> createState() => _BibleHomeScreenState();
}

class _BibleHomeScreenState extends State<BibleHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _sections = [
    ('ANTIGO TESTAMENTO', [
      ('Pentateuco', ['Gênesis', 'Êxodo', 'Levítico', 'Números', 'Deuteronômio']),
      ('Livros Históricos', ['Josué', 'Juízes', 'Rute', '1 Samuel', '2 Samuel', '1 Reis', '2 Reis', '1 Crônicas', '2 Crônicas', 'Esdras', 'Neemias', 'Ester']),
      ('Livros Poéticos', ['Jó', 'Salmos', 'Provérbios', 'Eclesiastes', 'Cantares']),
      ('Profetas Maiores', ['Isaías', 'Jeremias', 'Lamentações', 'Ezequiel', 'Daniel']),
      ('Profetas Menores', ['Oseias', 'Joel', 'Amós', 'Obadias', 'Jonas', 'Miqueias', 'Naum', 'Habacuque', 'Sofonias', 'Ageu', 'Zacarias', 'Malaquias']),
    ]),
    ('NOVO TESTAMENTO', [
      ('Evangelhos', ['Mateus', 'Marcos', 'Lucas', 'João']),
      ('Histórico', ['Atos']),
      ('Epístolas Paulo', ['Romanos', '1 Coríntios', '2 Coríntios', 'Gálatas', 'Efésios', 'Filipenses', 'Colossenses', '1 Tessalonicenses', '2 Tessalonicenses', '1 Timóteo', '2 Timóteo', 'Tito', 'Filemom']),
      ('Epístolas Gerais', ['Hebreus', 'Tiago', '1 Pedro', '2 Pedro', '1 João', '2 João', '3 João', 'Judas']),
      ('Profético', ['Apocalipse']),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final accent = AppColors.primary;
    final accentLight = accent.withValues(alpha: 0.12);

    List<BibleBook> filtered = BibleBook.all;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered.where((b) =>
        b.name.toLowerCase().contains(q) ||
        b.abbreviation.toLowerCase().contains(q)
      ).toList();
    }

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 110,
            floating: false,
            pinned: true,
            backgroundColor: bg,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bíblia Sagrada',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Nova Almeida Atualizada',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchHeaderDelegate(
              bg: surface,
              isDark: isDark,
              query: _query,
              onChanged: (v) => setState(() => _query = v),
              controller: _searchCtrl,
              accent: accent,
              accentLight: accentLight,
            ),
          ),
          if (_query.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _BookTile(
                    book: filtered[i],
                    isDark: isDark,
                    surface: surface,
                    accent: accent,
                    accentLight: accentLight,
                  ),
                  childCount: filtered.length,
                ),
              ),
            )
          else
            ..._sections.map((section) => SliverPadding(
              padding: const EdgeInsets.only(bottom: 8),
              sliver: _SectionList(section: section, isDark: isDark, surface: surface, accent: accent, accentLight: accentLight),
            )),
          const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
        ],
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Color bg;
  final bool isDark;
  final String query;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;
  final Color accent;
  final Color accentLight;

  _SearchHeaderDelegate({
    required this.bg, required this.isDark, required this.query, required this.onChanged,
    required this.controller, required this.accent, required this.accentLight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Buscar livro...',
          hintStyle: TextStyle(color: accent.withValues(alpha: 0.5), fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: accent, size: 20),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () { controller.clear(); onChanged(''); },
                  color: accent,
                )
              : null,
          filled: true,
          fillColor: accentLight,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
      ),
    );
  }

  @override
  double get maxExtent => 56;
  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate old) =>
    query != old.query || bg != old.bg;
}

class _SectionList extends StatelessWidget {
  final (String, List<(String, List<String>)>) section;
  final bool isDark;
  final Color surface;
  final Color accent;
  final Color accentLight;

  const _SectionList({required this.section, required this.isDark, required this.surface, required this.accent, required this.accentLight});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            section.$1,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...section.$2.map((group) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
                child: Text(
                  group.$1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              ...group.$2.map((name) {
                final book = BibleBook.all.firstWhere((b) => b.name == name);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _BookTile(
                    book: book,
                    isDark: isDark,
                    surface: surface,
                    accent: accent,
                    accentLight: accentLight,
                  ),
                );
              }),
            ],
          ),
        )),
      ]),
    );
  }
}

class _BookTile extends StatelessWidget {
  final BibleBook book;
  final bool isDark;
  final Color surface;
  final Color accent;
  final Color accentLight;

  const _BookTile({
    required this.book, required this.isDark, required this.surface,
    required this.accent, required this.accentLight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(AppRoutes.bibleChapter(book.id)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    book.abbreviation,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    book.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${book.chapters}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
