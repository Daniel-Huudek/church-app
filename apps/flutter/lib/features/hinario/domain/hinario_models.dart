class CtpHymn {
  final String number;
  final String title;
  final String lyrics;
  final String? reference;
  final String? history;
  final String? copyright;

  const CtpHymn({
    required this.number,
    required this.title,
    required this.lyrics,
    this.reference,
    this.history,
    this.copyright,
  });

  String get displayTitle => '$number - $title';

  factory CtpHymn.fromJson(Map<String, dynamic> json) {
    return CtpHymn(
      number: (json['number'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      lyrics: (json['lyrics'] as String?)?.trim() ?? '',
      reference: (json['reference'] as String?)?.trim(),
      history: (json['history'] as String?)?.trim(),
      copyright: (json['copyright'] as String?)?.trim(),
    );
  }
}
