import 'package:flutter_kts_template/core/utils/common.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

abstract class PagerDtoAbstract {
  final String page;
  final String pageSize;

  const PagerDtoAbstract({required this.page, required this.pageSize});

  factory PagerDtoAbstract.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('子类必须实现 fromJson 或使用具体工厂');
  }

  Map<String, dynamic> toJson() {
    return {'page': page, 'pageSize': pageSize};
  }

  List<String> validate() {
    final errors = <String>[];
    num p = safeParseNum(page);
    num s = safeParseNum(pageSize);
    if (p < 1) {
      errors.add(t.pageable.pageMin);
    }
    if (s < 1) {
      errors.add(t.pageable.pageSizeMin);
    }
    if (s > 100) {
      errors.add(t.pageable.pageSizeMax);
    }
    return errors;
  }

  void validateOrThrow() {
    final errors = validate();
    if (errors.isNotEmpty) {
      throw ArgumentError(t.pageable.paramsValidateError(errors: errors[0]));
    }
  }

  int get offset =>
      (safeParseNum(page) - 1).toInt() * safeParseNum(pageSize).toInt();

  @override
  String toString() => 'BasePageDto(page: $page, pageSize: $pageSize)';
}
