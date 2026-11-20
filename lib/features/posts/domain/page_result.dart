/// What a page load tells the caller. The posts themselves arrive through
/// the cache stream.
class PageResult {
  const PageResult({required this.endReached, this.stale = false});

  /// Fewer items than the page size came back. If your API returns `total`,
  /// `hasMore` or `nextCursor`, use that instead.
  final bool endReached;

  /// A refresh happened while this page was loading, so it was dropped
  /// instead of being appended to the new first page.
  final bool stale;
}
