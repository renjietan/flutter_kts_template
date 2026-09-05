
class ServerConfig {
  String port;
  String fallbackPort;

  ServerConfig({required this.port, required this.fallbackPort});
}

// part 'server.g.dart';   // 必须与当前文件名一致，自动生成 .g.dart

// @JsonSerializable()
// class ServerConfig {
//   String port;
//
//   ServerConfig({required this.port});

// factory ServerConfig.fromJson(Map<String, dynamic> json) => _$ServerConfigFromJson(json);
// Map<String, dynamic> toJson() => _$ServerConfigToJson(this);
// }
