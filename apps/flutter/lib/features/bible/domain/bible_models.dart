enum Testament { old, newTestament }

class BibleBook {
  final String id;
  final String name;
  final String abbreviation;
  final int chapters;
  final Testament testament;

  const BibleBook({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.chapters,
    required this.testament,
  });

  factory BibleBook.fromApi(Map<String, dynamic> json) {
    return BibleBook(
      id: json['id'] as String,
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String,
      chapters: json['chapters'] is List
          ? (json['chapters'] as List).length
          : (json['chapters'] as int),
      testament: (json['testament'] as String?) == 'OT'
          ? Testament.old
          : Testament.newTestament,
    );
  }

  static List<BibleBook> oldTestament = [
    BibleBook(id: 'GEN', name: 'Gênesis', abbreviation: 'Gn', chapters: 50, testament: Testament.old),
    BibleBook(id: 'EXO', name: 'Êxodo', abbreviation: 'Êx', chapters: 40, testament: Testament.old),
    BibleBook(id: 'LEV', name: 'Levítico', abbreviation: 'Lv', chapters: 27, testament: Testament.old),
    BibleBook(id: 'NUM', name: 'Números', abbreviation: 'Nm', chapters: 36, testament: Testament.old),
    BibleBook(id: 'DEU', name: 'Deuteronômio', abbreviation: 'Dt', chapters: 34, testament: Testament.old),
    BibleBook(id: 'JOS', name: 'Josué', abbreviation: 'Js', chapters: 24, testament: Testament.old),
    BibleBook(id: 'JDG', name: 'Juízes', abbreviation: 'Jz', chapters: 21, testament: Testament.old),
    BibleBook(id: 'RUT', name: 'Rute', abbreviation: 'Rt', chapters: 4, testament: Testament.old),
    BibleBook(id: '1SA', name: '1 Samuel', abbreviation: '1Sm', chapters: 31, testament: Testament.old),
    BibleBook(id: '2SA', name: '2 Samuel', abbreviation: '2Sm', chapters: 24, testament: Testament.old),
    BibleBook(id: '1KI', name: '1 Reis', abbreviation: '1Rs', chapters: 22, testament: Testament.old),
    BibleBook(id: '2KI', name: '2 Reis', abbreviation: '2Rs', chapters: 25, testament: Testament.old),
    BibleBook(id: '1CH', name: '1 Crônicas', abbreviation: '1Cr', chapters: 29, testament: Testament.old),
    BibleBook(id: '2CH', name: '2 Crônicas', abbreviation: '2Cr', chapters: 36, testament: Testament.old),
    BibleBook(id: 'EZR', name: 'Esdras', abbreviation: 'Ed', chapters: 10, testament: Testament.old),
    BibleBook(id: 'NEH', name: 'Neemias', abbreviation: 'Ne', chapters: 13, testament: Testament.old),
    BibleBook(id: 'EST', name: 'Ester', abbreviation: 'Et', chapters: 10, testament: Testament.old),
    BibleBook(id: 'JOB', name: 'Jó', abbreviation: 'Jó', chapters: 42, testament: Testament.old),
    BibleBook(id: 'PSA', name: 'Salmos', abbreviation: 'Sl', chapters: 150, testament: Testament.old),
    BibleBook(id: 'PRO', name: 'Provérbios', abbreviation: 'Pv', chapters: 31, testament: Testament.old),
    BibleBook(id: 'ECC', name: 'Eclesiastes', abbreviation: 'Ec', chapters: 12, testament: Testament.old),
    BibleBook(id: 'SNG', name: 'Cantares', abbreviation: 'Ct', chapters: 8, testament: Testament.old),
    BibleBook(id: 'ISA', name: 'Isaías', abbreviation: 'Is', chapters: 66, testament: Testament.old),
    BibleBook(id: 'JER', name: 'Jeremias', abbreviation: 'Jr', chapters: 52, testament: Testament.old),
    BibleBook(id: 'LAM', name: 'Lamentações', abbreviation: 'Lm', chapters: 5, testament: Testament.old),
    BibleBook(id: 'EZK', name: 'Ezequiel', abbreviation: 'Ez', chapters: 48, testament: Testament.old),
    BibleBook(id: 'DAN', name: 'Daniel', abbreviation: 'Dn', chapters: 12, testament: Testament.old),
    BibleBook(id: 'HOS', name: 'Oseias', abbreviation: 'Os', chapters: 14, testament: Testament.old),
    BibleBook(id: 'JOL', name: 'Joel', abbreviation: 'Jl', chapters: 3, testament: Testament.old),
    BibleBook(id: 'AMO', name: 'Amós', abbreviation: 'Am', chapters: 9, testament: Testament.old),
    BibleBook(id: 'OBA', name: 'Obadias', abbreviation: 'Ob', chapters: 1, testament: Testament.old),
    BibleBook(id: 'JON', name: 'Jonas', abbreviation: 'Jn', chapters: 4, testament: Testament.old),
    BibleBook(id: 'MIC', name: 'Miqueias', abbreviation: 'Mq', chapters: 7, testament: Testament.old),
    BibleBook(id: 'NAM', name: 'Naum', abbreviation: 'Na', chapters: 3, testament: Testament.old),
    BibleBook(id: 'HAB', name: 'Habacuque', abbreviation: 'Hc', chapters: 3, testament: Testament.old),
    BibleBook(id: 'ZEP', name: 'Sofonias', abbreviation: 'Sf', chapters: 3, testament: Testament.old),
    BibleBook(id: 'HAG', name: 'Ageu', abbreviation: 'Ag', chapters: 2, testament: Testament.old),
    BibleBook(id: 'ZEC', name: 'Zacarias', abbreviation: 'Zc', chapters: 14, testament: Testament.old),
    BibleBook(id: 'MAL', name: 'Malaquias', abbreviation: 'Ml', chapters: 4, testament: Testament.old),
  ];

  static List<BibleBook> newTestament = [
    BibleBook(id: 'MAT', name: 'Mateus', abbreviation: 'Mt', chapters: 28, testament: Testament.newTestament),
    BibleBook(id: 'MRK', name: 'Marcos', abbreviation: 'Mc', chapters: 16, testament: Testament.newTestament),
    BibleBook(id: 'LUK', name: 'Lucas', abbreviation: 'Lc', chapters: 24, testament: Testament.newTestament),
    BibleBook(id: 'JHN', name: 'João', abbreviation: 'Jo', chapters: 21, testament: Testament.newTestament),
    BibleBook(id: 'ACT', name: 'Atos', abbreviation: 'At', chapters: 28, testament: Testament.newTestament),
    BibleBook(id: 'ROM', name: 'Romanos', abbreviation: 'Rm', chapters: 16, testament: Testament.newTestament),
    BibleBook(id: '1CO', name: '1 Coríntios', abbreviation: '1Co', chapters: 16, testament: Testament.newTestament),
    BibleBook(id: '2CO', name: '2 Coríntios', abbreviation: '2Co', chapters: 13, testament: Testament.newTestament),
    BibleBook(id: 'GAL', name: 'Gálatas', abbreviation: 'Gl', chapters: 6, testament: Testament.newTestament),
    BibleBook(id: 'EPH', name: 'Efésios', abbreviation: 'Ef', chapters: 6, testament: Testament.newTestament),
    BibleBook(id: 'PHP', name: 'Filipenses', abbreviation: 'Fp', chapters: 4, testament: Testament.newTestament),
    BibleBook(id: 'COL', name: 'Colossenses', abbreviation: 'Cl', chapters: 4, testament: Testament.newTestament),
    BibleBook(id: '1TH', name: '1 Tessalonicenses', abbreviation: '1Ts', chapters: 5, testament: Testament.newTestament),
    BibleBook(id: '2TH', name: '2 Tessalonicenses', abbreviation: '2Ts', chapters: 3, testament: Testament.newTestament),
    BibleBook(id: '1TI', name: '1 Timóteo', abbreviation: '1Tm', chapters: 6, testament: Testament.newTestament),
    BibleBook(id: '2TI', name: '2 Timóteo', abbreviation: '2Tm', chapters: 4, testament: Testament.newTestament),
    BibleBook(id: 'TIT', name: 'Tito', abbreviation: 'Tt', chapters: 3, testament: Testament.newTestament),
    BibleBook(id: 'PHM', name: 'Filemom', abbreviation: 'Fm', chapters: 1, testament: Testament.newTestament),
    BibleBook(id: 'HEB', name: 'Hebreus', abbreviation: 'Hb', chapters: 13, testament: Testament.newTestament),
    BibleBook(id: 'JAS', name: 'Tiago', abbreviation: 'Tg', chapters: 5, testament: Testament.newTestament),
    BibleBook(id: '1PE', name: '1 Pedro', abbreviation: '1Pe', chapters: 5, testament: Testament.newTestament),
    BibleBook(id: '2PE', name: '2 Pedro', abbreviation: '2Pe', chapters: 3, testament: Testament.newTestament),
    BibleBook(id: '1JN', name: '1 João', abbreviation: '1Jo', chapters: 5, testament: Testament.newTestament),
    BibleBook(id: '2JN', name: '2 João', abbreviation: '2Jo', chapters: 1, testament: Testament.newTestament),
    BibleBook(id: '3JN', name: '3 João', abbreviation: '3Jo', chapters: 1, testament: Testament.newTestament),
    BibleBook(id: 'JUD', name: 'Judas', abbreviation: 'Jd', chapters: 1, testament: Testament.newTestament),
    BibleBook(id: 'REV', name: 'Apocalipse', abbreviation: 'Ap', chapters: 22, testament: Testament.newTestament),
  ];

  static List<BibleBook> get all => [...oldTestament, ...newTestament];
}

class BibleVerse {
  final String id;
  final String reference;
  final int chapter;
  final int verse;
  final String text;

  const BibleVerse({
    required this.id,
    required this.reference,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory BibleVerse.fromApi(Map<String, dynamic> json) {
    return BibleVerse(
      id: json['id'] as String,
      reference: json['reference'] as String? ?? '',
      chapter: int.parse((json['chapterId'] as String).split('.').last),
      verse: json['verseNumber'] != null
          ? int.parse(json['verseNumber'] as String)
          : int.parse((json['id'] as String).split('.').last),
      text: json['text'] as String? ?? '',
    );
  }
}

class BibleChapter {
  final String id;
  final String reference;
  final int number;

  const BibleChapter({
    required this.id,
    required this.reference,
    required this.number,
  });

  factory BibleChapter.fromApi(Map<String, dynamic> json) {
    return BibleChapter(
      id: json['id'] as String,
      reference: json['reference'] as String? ?? '',
      number: int.parse((json['id'] as String).split('.').last),
    );
  }
}
