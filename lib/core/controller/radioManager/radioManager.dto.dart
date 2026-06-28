import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

import '../../databaseManager/pagerable/pager.abstract.dto.dart';

class RadioManagerDto extends PagerDtoAbstract {
  final String keyword;
  RadioManagerDto({
    required super.page,
    required super.pageSize,
    this.keyword = "",
  });

  factory RadioManagerDto.fromJson(Map<String, dynamic> json) {
    return RadioManagerDto(
      page: json['page'] ?? "1", // 默认值 1
      pageSize: json['pageSize'] ?? "10", // 默认值 10
      keyword: json['keyword'] ?? "",
    );
  }

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'keyword': keyword};

  @override
  List<String> validate() {
    final errors = super.validate();
    if (keyword.isNotEmpty && keyword.length > 100) {
      errors.add(t.pageable.keywordValidateError(count: 100));
    }
    return errors;
  }

  @override
  String toString() =>
      'RadioManagerDto(page: $page, pageSize: $pageSize, keyword: $keyword)';
}
