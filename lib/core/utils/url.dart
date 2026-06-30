import 'common.dart';

int getId(List<String>? paths) {
  return safeParseNum(paths?.last ?? '0').toInt();
}

List<int> getIds(List<String>? paths) {
  List<int> ids = (paths?.last ?? '')
      .split("、")
      .map((item) => safeParseNum(item).toInt())
      .toList();
  return ids;
}
