import 'model/cpds_enums.dart';

class CpdsException implements Exception {
  const CpdsException(
    this.code, {
    this.params = const {},
    this.message,
  });

  final CpdsErrorCode code;
  final Map<String, dynamic> params;
  final String? message;

  @override
  String toString() => message ?? code.apiName;
}
