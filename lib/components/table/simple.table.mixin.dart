import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/components/table/simple.table.pager.dart';

import '../../theme/table.theme.dart';

mixin SimpleTableMixin on State<SimpleTable> {
  bool get isDark => widget.themePreset == ThemePreset.dark;
}
