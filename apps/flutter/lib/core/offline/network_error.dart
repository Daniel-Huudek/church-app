import 'dart:io';
import 'package:dio/dio.dart';

bool isNetworkError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.unknown:
        return error.error is SocketException;
      default:
        return false;
    }
  }
  return error is SocketException;
}
