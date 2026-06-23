// response_entity.dart
class ResponseEntity<T> {
  final int code;
  final String message;
  final T? data;

  ResponseEntity({required this.code, required this.message, this.data});

  factory ResponseEntity.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? parser,
  ) {
    return ResponseEntity<T>(
      code: json['code'] ?? -1,
      message: json['message'] ?? '', // 与后端一致
      data: parser != null ? parser(json['data']) : json['data'] as T?,
    );
  }

  bool get isSuccess => code == 200;
}
