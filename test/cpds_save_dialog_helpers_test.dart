import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/core/entities/keyLoaderDetails/keyLoaderDetailsEntity.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_save_dialog.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/entities/radios/radiosEntity.dart';
import 'package:flutter_test/flutter_test.dart';

CpdsFutureWarriorDevice _device({
  String nodeId = 'node-1',
  String deviceId = 'device-1',
}) {
  return CpdsFutureWarriorDevice(
    device: CpdsDevice(
      id: deviceId,
      type: CpdsDeviceType.multiBandRadio,
      model: 'model',
      alias: 'device-alias',
      ip: '',
    ),
    nodeId: nodeId,
    nodeName: 'node-name',
  );
}

KeyLoaderDetailsEntity _detail({
  int id = 1,
  int keyLoaderId = 10,
  String netNodePackageName = 'node-1',
  String dcPackageName = 'device-1',
  int? radioId = 20,
  String parentIdPath = 'unit-1',
}) {
  return KeyLoaderDetailsEntity(
    id: id,
    netNodePackageName: netNodePackageName,
    dcPackageName: dcPackageName,
    keyLoaderId: keyLoaderId,
    radioId: radioId,
    parentIdPath: parentIdPath,
    createdAt: DateTime(2026, 1, 1),
  );
}

RadiosEntity _radio(int id, String alias) {
  return RadiosEntity(
    id: id,
    alias: alias,
    consumer: '',
    location: '',
    sn: '',
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('cpdsDefaultRadioIdForDevice', () {
    test('重复行命中且原电台可用时，返回原 radioId', () {
      final result = cpdsDefaultRadioIdForDevice(
        device: _device(),
        parentIdPath: 'unit-1',
        existingDetails: [_detail()],
        availableRadioIds: {20, 21},
      );

      expect(result, 20);
    });

    test('原 radioId 不在当前电台列表时，跳过自动填充', () {
      final result = cpdsDefaultRadioIdForDevice(
        device: _device(),
        parentIdPath: 'unit-1',
        existingDetails: [_detail()],
        availableRadioIds: {21},
      );

      expect(result, isNull);
    });

    test('没有匹配的重复记录时，不自动填充', () {
      final result = cpdsDefaultRadioIdForDevice(
        device: _device(),
        parentIdPath: 'unit-1',
        existingDetails: [_detail(dcPackageName: 'other')],
        availableRadioIds: {20},
      );

      expect(result, isNull);
    });

    test('匹配时同时考虑 netNode、dcPackage 和 parentIdPath', () {
      final result = cpdsDefaultRadioIdForDevice(
        device: _device(),
        parentIdPath: 'unit-2',
        existingDetails: [_detail(parentIdPath: 'unit-1')],
        availableRadioIds: {20},
      );

      expect(result, isNull);
    });
  });

  group('cpdsAvailableRadios', () {
    test('原电台即使已改选其他电台，仍保留在当前行选项中', () {
      final result = cpdsAvailableRadios(
        radios: [_radio(20, '原电台'), _radio(21, '新电台'), _radio(22, '其他电台')],
        ownExistingRadioId: 20,
        ownSelectedRadioId: 21,
        boundRadioIds: {20, 30},
        selectedByOthers: {},
      );

      expect(result.map((radio) => radio.id), containsAll([20, 21, 22]));
    });

    test('其他行绑定的电台不会进入当前行选项', () {
      final result = cpdsAvailableRadios(
        radios: [_radio(20, '原电台'), _radio(22, '其他电台')],
        ownExistingRadioId: null,
        ownSelectedRadioId: null,
        boundRadioIds: {20},
        selectedByOthers: {},
      );

      expect(result.map((radio) => radio.id), isNot(contains(20)));
      expect(result.map((radio) => radio.id), contains(22));
    });

    test('其他行已选中的电台不会进入当前行选项', () {
      final result = cpdsAvailableRadios(
        radios: [_radio(20, '原电台'), _radio(22, '其他电台')],
        ownExistingRadioId: null,
        ownSelectedRadioId: null,
        boundRadioIds: {},
        selectedByOthers: {22},
      );

      expect(result.map((radio) => radio.id), isNot(contains(22)));
      expect(result.map((radio) => radio.id), contains(20));
    });
  });

  group('downlinkIp persistence contract', () {
    test('KeyLoaderDetailsEntity 保存并序列化 downlinkIp', () {
      final entity = KeyLoaderDetailsEntity(
        netNodePackageName: 'node-1',
        dcPackageName: 'device-1',
        keyLoaderId: 10,
        downlinkIp: '192.168.1.10',
        createdAt: DateTime(2026, 1, 1),
      );

      final json = entity.toJson();
      expect(json['downlinkIp'], '192.168.1.10');

      final restored = KeyLoaderDetailsEntity.fromJson(json);
      expect(restored.downlinkIp, '192.168.1.10');
    });

    test('cpdsDisplayDownlinkIp 空值时显示 --', () {
      expect(cpdsDisplayDownlinkIp(null), '--');
      expect(cpdsDisplayDownlinkIp(''), '--');
      expect(cpdsDisplayDownlinkIp('192.168.1.10'), '192.168.1.10');
    });
  });
}
