class PageResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  PageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  int get totalPages => (total / pageSize).ceil();
}
