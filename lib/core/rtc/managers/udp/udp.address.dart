import 'dart:io';

class UdpAddress {
  final InternetAddress address;
  final int port;

  UdpAddress(this.address, this.port) {
    if (port < 0 || port > 65535) throw ArgumentError.value(port, 'port');
  }

  factory UdpAddress.fromString(String str) {
    final parts = str.split(':');
    if (parts.length != 2) throw FormatException('格式错误');
    final ip = InternetAddress(parts[0]);
    final port = int.parse(parts[1]);
    return UdpAddress(ip, port);
  }

  @override
  String toString() => '${address.address}:$port';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UdpAddress &&
          runtimeType == other.runtimeType &&
          address.address == other.address.address && // 比较 IP 字符串
          port == other.port);

  @override
  int get hashCode => address.address.hashCode ^ port.hashCode;
}
