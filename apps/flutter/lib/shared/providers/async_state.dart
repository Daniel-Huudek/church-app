class AsyncState<T> {
  final T data;
  final bool loading;
  final String? error;
  final bool fromCache;

  const AsyncState({
    required this.data,
    this.loading = true,
    this.error,
    this.fromCache = false,
  });

  AsyncState<T> copyWith({
    T? data,
    bool? loading,
    String? error,
    bool? fromCache,
  }) {
    return AsyncState<T>(
      data: data ?? this.data,
      loading: loading ?? this.loading,
      error: error,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}
