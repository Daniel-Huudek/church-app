class CachedResult<T> {
  final T data;
  final bool fromCache;

  const CachedResult(this.data, {this.fromCache = false});
}
