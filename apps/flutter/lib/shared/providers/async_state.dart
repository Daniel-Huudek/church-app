class AsyncState<T> {
  final T data;
  final bool loading;
  final String? error;

  const AsyncState({
    required this.data,
    this.loading = true,
    this.error,
  });

  AsyncState<T> copyWith({T? data, bool? loading, String? error}) {
    return AsyncState<T>(
      data: data ?? this.data,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}
