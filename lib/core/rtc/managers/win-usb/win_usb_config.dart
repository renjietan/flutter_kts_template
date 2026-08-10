/// Windows WinUSB 通信参数配置。
///
/// 在调用 [WinUsbManager.connect] 之前通过
/// [WinUsbManager.setConfig] 设置，连接建立后会应用到对应管道。
class WinUsbConfig {
  /// 读取缓冲区大小（字节），默认 512（对齐 go.md 的 Read(512)）。
  final int readBufferSize;

  /// OUT 管道写入超时（毫秒），默认 5000ms（对齐 go.md 的 setPipeTimeout(EpOut, 5000)）。
  final int writeTimeoutMs;

  /// IN 管道读取超时（毫秒），同时作为轮询间隔，默认 100ms。
  ///
  /// 该值越小轮询越频繁、接收延迟越低，但 CPU 占用越高。
  /// 它会被设置为 IN 管道的 PIPE_TRANSFER_TIMEOUT，无数据时读取在此时长内返回。
  final int readTimeoutMs;

  const WinUsbConfig({
    this.readBufferSize = 512,
    this.writeTimeoutMs = 5000,
    this.readTimeoutMs = 100,
  });

  WinUsbConfig copyWith({
    int? readBufferSize,
    int? writeTimeoutMs,
    int? readTimeoutMs,
  }) {
    return WinUsbConfig(
      readBufferSize: readBufferSize ?? this.readBufferSize,
      writeTimeoutMs: writeTimeoutMs ?? this.writeTimeoutMs,
      readTimeoutMs: readTimeoutMs ?? this.readTimeoutMs,
    );
  }
}
