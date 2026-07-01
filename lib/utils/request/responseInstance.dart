class ResponseInstance<T> {
  final int code;
  final String message;
  final T? data;

  ResponseInstance({required this.code, required this.message, this.data});

  factory ResponseInstance.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? parser,
  ) {
    return ResponseInstance<T>(
      code: json['code'] ?? -1,
      message: json['message'] ?? '',
      data: parser != null ? parser(json['data']) : json['data'] as T?,
    );
  }

  bool get isSuccess => code == 200;
}
