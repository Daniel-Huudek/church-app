class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final List<String>? errors;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? true,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}

class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final List<String>? errors;

  const ApiError({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}
