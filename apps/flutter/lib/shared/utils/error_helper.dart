import 'package:dio/dio.dart';

String formatError(dynamic error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tempo limite excedido. Verifique sua conexão.';
      case DioExceptionType.connectionError:
        return 'Erro de conexão. Verifique sua internet.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data is Map
            ? (error.response!.data as Map)['message'] ?? ''
            : '';
        if (statusCode == 401) return 'Sessão expirada. Faça login novamente.';
        if (statusCode == 404) return 'Recurso não encontrado.';
        if (statusCode == 409) return message.isNotEmpty ? message : 'Conflito ao salvar.';
        if (statusCode != null && statusCode >= 500) return 'Erro interno do servidor.';
        return message.isNotEmpty ? message : 'Erro inesperado ($statusCode).';
      case DioExceptionType.cancel:
        return 'Operação cancelada.';
      default:
        return 'Erro de rede. Verifique sua conexão.';
    }
  }
  if (error is FormatException) return 'Resposta inválida do servidor.';
  return error.toString();
}
