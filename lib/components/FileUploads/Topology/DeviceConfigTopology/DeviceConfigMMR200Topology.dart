class DeviceConfiguration {
  final String alias;
  final Map<String, Channel> channels;
  final int dhcp;
  final FileInfo file;
  final String gateway;
  final String ip;
  final String netmask;

  DeviceConfiguration({
    required this.alias,
    required this.channels,
    required this.dhcp,
    required this.file,
    required this.gateway,
    required this.ip,
    required this.netmask,
  });

  factory DeviceConfiguration.fromJson(Map<String, dynamic> json) {
    final channelsMap = <String, Channel>{};
    if (json['Channels'] != null) {
      (json['Channels'] as Map<String, dynamic>).forEach((key, value) {
        channelsMap[key] = Channel.fromJson(value);
      });
    }

    return DeviceConfiguration(
      alias: json['Alias'] as String? ?? '',
      channels: channelsMap,
      dhcp: json['Dhcp'] as int,
      file: FileInfo.fromJson(json['File']),
      gateway: json['Gateway'] as String,
      ip: json['IP'] as String,
      netmask: json['Netmask'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'Alias': alias,
    'Channels': channels.map((key, value) => MapEntry(key, value.toJson())),
    'Dhcp': dhcp,
    'File': file.toJson(),
    'Gateway': gateway,
    'IP': ip,
    'Netmask': netmask,
  };
}

class Channel {
  final int mac;
  final String subnet;

  Channel({required this.mac, required this.subnet});

  factory Channel.fromJson(Map<String, dynamic> json) =>
      Channel(mac: json['Mac'] as int, subnet: json['Subnet'] as String);

  Map<String, dynamic> toJson() => {'Mac': mac, 'Subnet': subnet};
}

class FileInfo {
  final String guid;
  final String layer;
  final String model;

  FileInfo({required this.guid, required this.layer, required this.model});

  factory FileInfo.fromJson(Map<String, dynamic> json) => FileInfo(
    guid: json['Guid'] as String,
    layer: json['Layer'] as String,
    model: json['Model'] as String,
  );

  Map<String, dynamic> toJson() => {
    'Guid': guid,
    'Layer': layer,
    'Model': model,
  };
}
