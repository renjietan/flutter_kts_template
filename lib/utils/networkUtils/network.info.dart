/// 网络接口信息数据类
class NetworkInterfaceInfo {
  final String interfaceName;
  final String ip;
  final String mask;
  final String broadcast;

  NetworkInterfaceInfo({
    required this.interfaceName,
    required this.ip,
    required this.mask,
    required this.broadcast,
  });

  @override
  String toString() {
    return '接口: $interfaceName, IP: $ip, 掩码: $mask, 广播: $broadcast';
  }
}
