class BaseListResponse<T> {
  final List<T> list;
  final int total;

  BaseListResponse({required this.list, required this.total});

  factory BaseListResponse.fromJson(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      (data["list"] ?? []) as List,
    );
    return BaseListResponse(
      list: list.map((item) => fromJsonT(item)).toList(),
      total: (data['total'] ?? 0) as int,
    );
  }
}
