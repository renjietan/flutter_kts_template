// 独立测试脚本：验证 WinUSB 连接（完全对齐 go.md）
// 运行方式: dart test\usb_test.dart
//
// 流程对齐 go.md 的成功案例:
// 1. ListDevices: 注册表枚举 Service=WINUSB 的设备，读 DeviceInterfaceGUIDs
//    构造路径，canOpenAsWinUsb 验证（纯读取，不写注册表）
// 2. Open: CreateFile(FILE_FLAG_OVERLAPPED) + WinUsb_Initialize
// 3. queryEndpoints: QueryInterfaceSettings(0) + 循环 QueryPipe，按 bit7 分 IN/OUT
// 4. setPipeTimeout: SetPipePolicy(PIPE_TRANSFER_TIMEOUT) 对 IN/OUT 各设一次
// 5. Write/Read: WinUsb_WritePipe / WinUsb_ReadPipe
// 6. Close: WinUsb_Free + CloseHandle
//
// 注意: 设备必须已通过公司 INF (Linux_device_(Interface_2).inf) 正确安装，
// 由其 [AddDeviceInterfaceGUID] 段在插入时自动写入 DeviceInterfaceGUIDs，
// winusb.sys 才会创建符号链接。若 canOpenAsWinUsb 全部失败（CreateFile error=2），
// 说明符号链接未创建，请重新插拔设备或以管理员身份重装驱动。

import 'dart:typed_data';

import 'package:flutter_kts_template/core/rtc/managers/win-usb/win_usb_ffi.dart';

void main() async {
  print('========================================');
  print('  WinUSB 测试 (对齐 go.md)');
  print('========================================\n');

  // 第 1 步：注册表枚举（对齐 go.md 的 ListDevices）
  print('[1] listWinUsbDevicesFromRegistry...');
  print('    (读取 DeviceInterfaceGUIDs，canOpenAsWinUsb 验证，不写注册表)');
  final devices = await listWinUsbDevicesFromRegistry();
  print('  找到 ${devices.length} 个可打开的 WinUSB 设备:');
  for (final d in devices) {
    print('    - $d');
  }
  print('');

  if (devices.isEmpty) {
    print('❌ 没有找到可打开的 WinUSB 设备');
    print('   可能原因:');
    print('   1. 设备未连接');
    print('   2. 没有 Service=WINUSB 的设备');
    print('   3. 设备接口符号链接未创建（DeviceInterfaceGUIDs 已存在但 winusb.sys 未生成链接）');
    print('      → 请重新插拔设备，或以管理员身份重装公司 INF 驱动');
    print('   4. 路径构造用的 GUID 不匹配');
    return;
  }

  // 第 2 步：筛选目标设备
  const targetVid = 0x0525;
  const targetPid = 0xA4A1;
  const targetIf = 2;
  print('[2] 筛选目标设备 VID=0x0525 PID=0xA4A1 IF=$targetIf ...');
  final target = devices.firstWhere(
    (d) => d.vid == targetVid && d.pid == targetPid && d.interfaceNumber == targetIf,
    orElse: () => throw StateError('未找到目标设备'),
  );
  print('  目标设备: ${target.devicePath}');
  print('');

  // 第 3 步：Open（对齐 go.md 的 Open）
  print('[3] Open: CreateFile + WinUsb_Initialize...');
  final deviceHandle = openDevice(target.devicePath);
  print('  设备句柄: $deviceHandle');

  final interfaceHandle = winUsbInitialize(deviceHandle);
  print('  接口句柄: $interfaceHandle');
  print('  ✅ Open 成功！');
  print('');

  // 第 4 步：queryEndpoints（对齐 go.md 的 queryEndpoints）
  print('[4] queryEndpoints...');
  final settings = queryInterfaceSettings(interfaceHandle, 0);
  print('  bInterfaceNumber: ${settings.interfaceNumber}');
  print('  bNumEndpoints: ${settings.numEndpoints}');

  final pipes = listPipes(interfaceHandle, 0);
  print('  发现 ${pipes.length} 个管道:');
  int inPipeId = 0;
  int outPipeId = 0;
  for (final p in pipes) {
    final direction = isInPipe(p.pipeId) ? 'IN' : 'OUT';
    final typeName = switch (p.pipeType) {
      PIPE_TYPE_BULK => 'BULK',
      PIPE_TYPE_INTERRUPT => 'INTERRUPT',
      PIPE_TYPE_ISOCHRONOUS => 'ISOCHRONOUS',
      PIPE_TYPE_CONTROL => 'CONTROL',
      _ => 'UNKNOWN(${p.pipeType})',
    };
    print('    PipeId=0x${p.pipeId.toRadixString(16).padLeft(2, '0')} '
        '$direction $typeName maxPacket=${p.maximumPacketSize}');
    // 对齐 go.md：PipeId & 0x80 != 0 为 IN，否则为 OUT
    if (isInPipe(p.pipeId)) {
      inPipeId = p.pipeId;
    } else {
      outPipeId = p.pipeId;
    }
  }
  print('');

  // 第 5 步：setPipeTimeout（对齐 go.md 的 setPipeTimeout，5000ms）
  print('[5] setPipeTimeout (5000ms)...');
  if (inPipeId != 0) {
    setPipeTimeout(interfaceHandle, inPipeId, 5000);
    print('  IN 管道 0x${inPipeId.toRadixString(16).padLeft(2, '0')} 超时=5000ms');
  }
  if (outPipeId != 0) {
    setPipeTimeout(interfaceHandle, outPipeId, 5000);
    print('  OUT 管道 0x${outPipeId.toRadixString(16).padLeft(2, '0')} 超时=5000ms');
  }
  print('');

  // 第 6 步：Write 测试（对齐 go.md 的 Write）
  if (outPipeId != 0) {
    print('[6] Write [0x10, 0x00]...');
    final testData = Uint8List.fromList([0x10, 0x00]);
    try {
      final written = winUsbWritePipe(interfaceHandle, outPipeId, testData);
      print('  ✅ 写入成功: $written 字节');
    } catch (e) {
      print('  ❌ 写入失败: $e');
    }
  }
  print('');

  // 第 7 步：Read 测试（对齐 go.md 的 Read(512)）
  if (inPipeId != 0) {
    print('[7] Read (buffer=512)...');
    try {
      final data = winUsbReadPipe(interfaceHandle, inPipeId, 512);
      if (data.isNotEmpty) {
        print('  ✅ 收到 ${data.length} 字节: $data');
      } else {
        print('  (无数据，可能是超时)');
      }
    } catch (e) {
      print('  ❌ 读取失败: $e');
    }
  }
  print('');

  // 第 8 步：Close（对齐 go.md 的 Close）
  print('[8] Close...');
  winUsbFree(interfaceHandle);
  closeDevice(deviceHandle);
  print('  ✅ 已释放');
  print('');

  print('========================================');
  print('  测试完成 - 设备连接成功！');
  print('========================================');
}
