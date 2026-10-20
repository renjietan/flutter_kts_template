import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/hardcoded_dimension_rule.dart';

/// The top-level variable the Dart Analysis Server looks for when loading
/// this plugin. It must be named `plugin`.
final plugin = CpdLintsPlugin();

/// Registers the regression rules that enforce the CPDS responsive-layout
/// conventions (`.w` / `.h` / `.sp` / `.r` unit extensions).
class CpdLintsPlugin extends Plugin {
  @override
  String get name => 'cpd_lints';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(HardcodedDimensionRule());
  }
}
