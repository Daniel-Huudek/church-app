import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Endereço retornado por uma consulta de CEP (ViaCEP).
class CepAddress {
  final String zipCode;
  final String street;
  final String neighborhood;
  final String city;
  final String state;

  const CepAddress({
    required this.zipCode,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  factory CepAddress.fromViaCep(Map<String, dynamic> json) {
    final rawCep = (json['cep'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
    return CepAddress(
      zipCode: formatCep(rawCep),
      street: (json['logradouro'] as String? ?? '').trim(),
      neighborhood: (json['bairro'] as String? ?? '').trim(),
      city: (json['localidade'] as String? ?? '').trim(),
      state: (json['uf'] as String? ?? '').trim().toUpperCase(),
    );
  }
}

/// Mantém apenas dígitos do CEP (máx. 8).
String normalizeCep(String value) =>
    value.replaceAll(RegExp(r'\D'), '').clampLength(8);

/// Formata CEP como `00000-000` quando completo.
String formatCep(String value) {
  final digits = normalizeCep(value);
  if (digits.length <= 5) return digits;
  return '${digits.substring(0, 5)}-${digits.substring(5)}';
}

extension on String {
  String clampLength(int max) => length <= max ? this : substring(0, max);
}

class CepNotFoundException implements Exception {
  @override
  String toString() => 'CEP não encontrado';
}

class CepLookupService {
  CepLookupService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://viacep.com.br',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {'Accept': 'application/json'},
              ),
            );

  final Dio _dio;

  /// Consulta o ViaCEP. Lança [CepNotFoundException] se o CEP for inválido
  /// ou não existir. Retorna `null` se ainda não houver 8 dígitos.
  Future<CepAddress?> lookup(String cep) async {
    final digits = normalizeCep(cep);
    if (digits.length != 8) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>('/ws/$digits/json/');
      final data = response.data;
      if (data == null || data['erro'] == true || data['erro'] == 'true') {
        throw CepNotFoundException();
      }
      final address = CepAddress.fromViaCep(data);
      if (address.city.isEmpty || address.state.isEmpty) {
        throw CepNotFoundException();
      }
      return address;
    } on CepNotFoundException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw CepNotFoundException();
      }
      rethrow;
    }
  }
}

final cepLookupServiceProvider = Provider<CepLookupService>((ref) {
  return CepLookupService();
});
