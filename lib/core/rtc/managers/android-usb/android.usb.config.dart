import 'package:usb_serial/usb_serial.dart';

/// Android USB 串口参数配置。
///
/// 在调用 [AndroidUsbManager.connect] 之前通过
/// [AndroidUsbManager.setConfig] 设置，连接建立后会应用到对应 [UsbPort]。
/// 默认值为常见的 `115200 8N1`，并拉高 DTR / RTS。
class AndroidUsbConfig {
  final int baudRate;
  final int dataBits;
  final int stopBits;
  final int parity;
  final bool dtr;
  final bool rts;

  /// 流控类型，`null` 表示不修改（保持驱动默认）。
  /// 取值参考 [UsbPort.FLOW_CONTROL_OFF] / [UsbPort.FLOW_CONTROL_RTS_CTS] 等。
  final int? flowControl;

  const AndroidUsbConfig({
    this.baudRate = 115200,
    this.dataBits = UsbPort.DATABITS_8,
    this.stopBits = UsbPort.STOPBITS_1,
    this.parity = UsbPort.PARITY_NONE,
    this.dtr = true,
    this.rts = true,
    this.flowControl,
  });

  AndroidUsbConfig copyWith({
    int? baudRate,
    int? dataBits,
    int? stopBits,
    int? parity,
    bool? dtr,
    bool? rts,
    int? flowControl,
  }) {
    return AndroidUsbConfig(
      baudRate: baudRate ?? this.baudRate,
      dataBits: dataBits ?? this.dataBits,
      stopBits: stopBits ?? this.stopBits,
      parity: parity ?? this.parity,
      dtr: dtr ?? this.dtr,
      rts: rts ?? this.rts,
      flowControl: flowControl ?? this.flowControl,
    );
  }
}
