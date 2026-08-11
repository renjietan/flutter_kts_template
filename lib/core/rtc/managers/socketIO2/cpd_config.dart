// CPDS 协议配置与时间常量
class CpdConfig {
  CpdConfig._();

  // Magic 前缀: 0xEEDDCCBB (网络字节序 EE DD CC BB)
  static const int magic = 0xEEDDCCBB;

  // 端口
  static const int cpdcPort = 39001;
  static const int cpdsPort = 39002;

  // 最大负载
  static const int maxUdpPayload = 1400;
  static const int maxPacketSize = 1396;

  // 分包负载
  static const int chunkPayloadSize = 1200;

  // 最大文件大小 1 MiB
  static const int maxFileSize = 1048576;

  // 传输负载速率 1 Mbit/s
  static const int transferPayloadRateBps = 1000000;

  // 时间常量
  static const Duration discoverWindow = Duration(seconds: 5);
  static const Duration discoverInterval = Duration(seconds: 1);
  static const Duration authWindow = Duration(seconds: 5);
  static const Duration authRetryInterval = Duration(seconds: 1);
  static const Duration transferStartRefreshInterval = Duration(seconds: 1);
  static const Duration transferWaitRetryInterval = Duration(seconds: 1);
  static const Duration transferSilenceTimeout = Duration(seconds: 10);
  static const Duration transferNoProgressTimeout = Duration(seconds: 30);
  static const Duration parseResultWaitTimeout = Duration(seconds: 35);
}
