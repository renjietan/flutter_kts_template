/// 日志类别，对应一个独立的 .log 文件名。
enum LogCategory {
  http('http.log'),
  udpDistribution('udp_distribution.log'),
  importParamsPacket('import_params_packet.log'),
  exportParamsPacket('export_params_packet.log');

  const LogCategory(this.fileName);
  final String fileName;
}