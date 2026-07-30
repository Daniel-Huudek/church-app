/// Nome preferencial do membro: apelido, se houver; senão nome completo.
String preferredPersonName({required String name, String? nickname}) {
  final nick = nickname?.trim();
  if (nick != null && nick.isNotEmpty) return nick;
  return name.trim();
}

/// Nome para copiar na escala: apelido, se houver; senão nome abreviado.
String scaleCopyDisplayName({required String name, String? nickname}) {
  final nick = nickname?.trim();
  if (nick != null && nick.isNotEmpty) return nick;
  return abbreviatePersonName(name);
}

/// Abrevia nome completo para escala/WhatsApp: primeiro nome + iniciais do restante.
///
/// Exemplos:
/// - `João Silva Santos` → `João S. S.`
/// - `Maria da Silva` → `Maria S.` (partículas de/da/do são ignoradas)
/// - `Ana` → `Ana`
String abbreviatePersonName(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first;

  final first = parts.first;
  final initials = <String>[];
  for (final part in parts.skip(1)) {
    if (_isNameParticle(part)) continue;
    initials.add('${part[0].toUpperCase()}.');
  }

  if (initials.isEmpty) return first;
  return '$first ${initials.join(' ')}';
}

bool _isNameParticle(String part) {
  const particles = {
    'de',
    'da',
    'do',
    'dos',
    'das',
    'e',
    'di',
    'du',
    'del',
    'della',
  };
  return particles.contains(part.toLowerCase());
}
