class BaseResponse<T> {
  final int code;
  final String message;
  final T data;

  BaseResponse({required this.code, required this.message, required this.data});
}
