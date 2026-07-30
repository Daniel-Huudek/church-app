import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

class BackupApi {
  final ApiClient _client;

  BackupApi(this._client);

  /// Baixa o backup e grava um arquivo JSON temporário. Retorna o path.
  Future<File> downloadBackupFile() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      ApiConfig.backup,
      options: Options(
        responseType: ResponseType.json,
        receiveTimeout: const Duration(minutes: 2),
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true || body['data'] == null) {
      throw Exception(body?['message']?.toString() ?? 'Falha ao gerar backup');
    }

    final backup = body['data'] as Map<String, dynamic>;
    final exportedAt = backup['exportedAt']?.toString() ?? DateTime.now().toIso8601String();
    final datePart = exportedAt.length >= 10 ? exportedAt.substring(0, 10) : 'backup';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/church-backup-$datePart.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(backup));
    return file;
  }

  Future<Map<String, dynamic>> restoreFromFile({
    required String filePath,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final response = await _client.dio.post<Map<String, dynamic>>(
      ApiConfig.backupRestore,
      data: form,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(body?['message']?.toString() ?? 'Falha ao restaurar backup');
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }
}
