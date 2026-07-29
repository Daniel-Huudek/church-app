import 'package:url_launcher/url_launcher.dart';

/// Digits only, with Brazil country code `55` when the number looks local.
String whatsAppPhoneDigits(String phone) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return digits;

  // Already includes country code (e.g. 5511999999999).
  if (digits.startsWith('55') && digits.length >= 12) return digits;

  // Brazilian mobile (11) or landline (10).
  if (digits.length == 10 || digits.length == 11) {
    return '55$digits';
  }

  return digits;
}

Uri? whatsAppUri(String phone) {
  final digits = whatsAppPhoneDigits(phone);
  if (digits.isEmpty) return null;
  return Uri.parse('https://wa.me/$digits');
}

/// Single-line query suitable for Google Maps search.
String mapsQueryFromAddress({
  String? street,
  String? number,
  String? complement,
  String? neighborhood,
  String? city,
  String? state,
  String? zipCode,
}) {
  final parts = <String>[
    if (street != null && street.isNotEmpty)
      [street, if (number != null && number.isNotEmpty) number].join(', '),
    if (complement != null && complement.isNotEmpty) complement,
    if (neighborhood != null && neighborhood.isNotEmpty) neighborhood,
    if (city != null && city.isNotEmpty && state != null && state.isNotEmpty)
      '$city - $state'
    else if (city != null && city.isNotEmpty)
      city
    else if (state != null && state.isNotEmpty)
      state,
    if (zipCode != null && zipCode.isNotEmpty) zipCode,
  ];
  return parts.join(', ');
}

Uri? googleMapsUri({
  String? street,
  String? number,
  String? complement,
  String? neighborhood,
  String? city,
  String? state,
  String? zipCode,
}) {
  final query = mapsQueryFromAddress(
    street: street,
    number: number,
    complement: complement,
    neighborhood: neighborhood,
    city: city,
    state: state,
    zipCode: zipCode,
  );
  if (query.trim().isEmpty) return null;
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': query,
  });
}

Future<bool> openExternalUri(Uri? uri) async {
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
