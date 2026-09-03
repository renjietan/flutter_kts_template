import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_package_panel.dart';
import 'package:flutter_test/flutter_test.dart';

CpdsNode _node(String id, {int nodeType = 0}) => CpdsNode(
  id: id,
  guid: 'guid-$id',
  name: id,
  networkSegment: '',
  nodeType: nodeType,
  model: '',
  devices: const [],
);

CpdsUnit _unit(String id, {List<String> nodeIds = const []}) =>
    CpdsUnit(id: id, name: id, nodeIds: nodeIds, subUnits: const []);

CpdsPackage _package(List<CpdsUnit> units, List<CpdsNode> nodes) =>
    CpdsPackage(
      fileName: 'test.zip',
      fileSize: 0,
      expandedSize: 0,
      requiredWorkspace: 0,
      units: units,
      nodes: nodes,
    );

Widget _wrap(CpdsPackage package) {
  LocaleSettings.setLocaleSync(AppLocale.zh);
  return TranslationProvider(
    child: MaterialApp(
      home: Scaffold(
        body: CpdsPackagePanel(
          state: CpdsApplicationState(package: package),
          uploading: false,
          onBrowse: () {},
          onSelectNode: (_) {},
          onSelectFutureWarrior: (_) {},
        ),
      ),
    ),
  );
}

Finder _treeText(String text) => find.descendant(
  of: find.byType(ListView),
  matching: find.text(text),
);

void main() {
  testWidgets('默认展开，点击 unit 可收起/展开', (tester) async {
    final package = _package(
      [_unit('u1', nodeIds: ['n1', 'n3'])],
      [_node('n1', nodeType: 1), _node('n3', nodeType: 2)],
    );
    await tester.pumpWidget(_wrap(package));

    // 默认全部展开。
    expect(find.text('u1'), findsOneWidget);
    expect(_treeText('n3'), findsOneWidget);
    expect(find.text('未来战士（1）'), findsOneWidget);
    expect(find.text('n1'), findsNothing); // nodeType==1 已归入 CS

    // 收起 unit。
    await tester.tap(find.text('u1'));
    await tester.pump();

    expect(_treeText('n3'), findsNothing);
    expect(find.text('未来战士（1）'), findsNothing);

    // 再展开 unit。
    await tester.tap(find.text('u1'));
    await tester.pump();

    expect(find.text('n3'), findsOneWidget);
    expect(find.text('未来战士（1）'), findsOneWidget);
  });

  testWidgets('没有 nodeType==1 时不显示 CS', (tester) async {
    final package = _package(
      [_unit('u1', nodeIds: ['n3'])],
      [_node('n3', nodeType: 2)],
    );
    await tester.pumpWidget(_wrap(package));

    // 默认展开，n3 可见。
    expect(_treeText('n3'), findsOneWidget);
    expect(find.textContaining('未来战士'), findsNothing);
  });

  testWidgets('空 unit 是叶子，点击不展开也不报错', (tester) async {
    final package = _package([_unit('u1')], []);
    await tester.pumpWidget(_wrap(package));

    expect(find.text('u1'), findsOneWidget);
    await tester.tap(find.text('u1'));
    await tester.pump();
    expect(find.text('u1'), findsOneWidget);
  });

  testWidgets('Windows：搜索即输即搜并自动展开祖先', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final package = _package(
        [_unit('u1', nodeIds: ['n3', 'n4'])],
        [_node('n3', nodeType: 2), _node('n4', nodeType: 0)],
      );
      await tester.pumpWidget(_wrap(package));

      expect(_treeText('n3'), findsOneWidget);
      expect(_treeText('n4'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'n3');
      await tester.pump();

      expect(_treeText('n3'), findsOneWidget);
      expect(_treeText('n4'), findsNothing);
      expect(_treeText('u1'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android：输入不搜索，按键盘搜索键才搜索', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final package = _package(
        [_unit('u1', nodeIds: ['n3'])],
        [_node('n3', nodeType: 2)],
      );
      await tester.pumpWidget(_wrap(package));

      await tester.enterText(find.byType(TextField), 'n99');
      await tester.pump();
      expect(_treeText('n3'), findsOneWidget); // 输入时未搜索

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(_treeText('n3'), findsNothing); // 按搜索键后搜索 n99，n3 被过滤
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('搜索后仍可手动展开/收起', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final package = _package(
        [_unit('u1', nodeIds: ['n3'])],
        [_node('n3', nodeType: 2)],
      );
      await tester.pumpWidget(_wrap(package));

      await tester.enterText(find.byType(TextField), 'n3');
      await tester.pump();
      expect(_treeText('n3'), findsOneWidget); // 搜索后自动展开

      await tester.tap(find.text('u1'));
      await tester.pump();
      expect(_treeText('n3'), findsNothing); // 搜索后仍可收起
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
