import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Prevents raw numeric literals from being reintroduced as dimensions.
///
/// Dimension-like named arguments (such as `width`, `height`, `size` and
/// `fontSize`) must use the responsive unit extensions provided by
/// `flutter_screenutil` instead of plain numbers.
class HardcodedDimensionRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'hardcoded_dimension',
    'Responsive unit extension (.w/.h/.sp/.r) expected instead of a raw '
        'numeric literal.',
    correctionMessage: 'Replace the number with the matching unit extension '
        '(for example 100.w for a width, 16.sp for a fontSize).',
    severity: DiagnosticSeverity.WARNING,
  );

  HardcodedDimensionRule()
      : super(
          name: 'hardcoded_dimension',
          description: 'Dimension-like named arguments must use the '
              'responsive unit extensions instead of raw numeric literals.',
        );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addNamedExpression(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const Set<String> _dimensionNames = {
    'width',
    'height',
    'size',
    'fontSize',
    'minWidth',
    'maxWidth',
    'minHeight',
    'maxHeight',
    'left',
    'right',
    'top',
    'bottom',
    'horizontal',
    'vertical',
    'radius',
  };

  /// Types whose positional constructor arguments are dimensions.
  static const Set<String> _positionalDimensionTypes = {
    'EdgeInsets',
    'Offset',
  };

  /// Types whose named constructor accepts raw radius/offset literals.
  static const Map<String, Set<String>> _literalConstructors = {
    'BorderRadius': {'circular'},
    'Radius': {'circular', 'elliptical'},
  };

  final HardcodedDimensionRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitNamedExpression(NamedExpression node) {
    if (!context.isInLibDir) {
      return;
    }
    if (!_dimensionNames.contains(node.name.label.name)) {
      return;
    }
    _reportIfRawNumber(node.expression);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!context.isInLibDir) {
      return;
    }
    final constructorName = node.constructorName;
    final type = constructorName.type;
    final typeName = type.name.lexeme;
    final constructorNamePart = constructorName.name?.name;

    if (_positionalDimensionTypes.contains(typeName) ||
        (_literalConstructors[typeName]?.contains(constructorNamePart) ??
            false)) {
      _reportRawNumbers(node.argumentList.arguments);
    }
  }

  void _reportRawNumbers(List<Expression> arguments) {
    for (final argument in arguments) {
      _reportIfRawNumber(argument);
    }
  }

  void _reportIfRawNumber(Expression expression) {
    if (expression is IntegerLiteral) {
      final value = expression.value;
      if (value != null && value != 0) {
        rule.reportAtNode(expression);
      }
    } else if (expression is DoubleLiteral) {
      if (expression.value != 0) {
        rule.reportAtNode(expression);
      }
    }
  }
}
