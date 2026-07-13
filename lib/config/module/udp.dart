class UdpConfig {
  String address;
  String port;
  Duration timeoutDuration;

  UdpConfig({
    required this.port,
    required this.address,
    required this.timeoutDuration,
  });

  @override
  String toString() {
    // TODO: implement toString
    return "$address:$port";
  }
}
