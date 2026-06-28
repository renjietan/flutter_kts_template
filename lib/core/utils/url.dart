import 'common.dart';

int getId(List<String>? paths) {
  return safeParseNum(paths?.last ?? '0').toInt();
}
