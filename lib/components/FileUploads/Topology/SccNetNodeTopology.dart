// 根类：网络节点配置
class SccNetNodeTopology {
  final BasicInfo basicInfo;
  final FileInfo file;
  final SystemConfiguration systemConfiguration;

  SccNetNodeTopology({
    required this.basicInfo,
    required this.file,
    required this.systemConfiguration,
  });

  // 手动 fromJson
  factory SccNetNodeTopology.fromJson(Map<String, dynamic> json) {
    return SccNetNodeTopology(
      basicInfo: BasicInfo.fromJson(json['BasicInfo'] as Map<String, dynamic>),
      file: FileInfo.fromJson(json['File'] as Map<String, dynamic>),
      systemConfiguration: SystemConfiguration.fromJson(
        json['SystemConfiguration'] as Map<String, dynamic>,
      ),
    );
  }

  // 手动 toJson
  Map<String, dynamic> toJson() => {
    'BasicInfo': basicInfo.toJson(),
    'File': file.toJson(),
    'SystemConfiguration': systemConfiguration.toJson(),
  };
}

// BasicInfo 子类
class BasicInfo {
  final String networkSegment;
  final String nodeName;
  final int nodeType;

  BasicInfo({
    required this.networkSegment,
    required this.nodeName,
    required this.nodeType,
  });

  factory BasicInfo.fromJson(Map<String, dynamic> json) => BasicInfo(
    networkSegment: json['NetworkSegment'] as String,
    nodeName: json['NodeName'] as String,
    nodeType: json['NodeType'] as int,
  );

  Map<String, dynamic> toJson() => {
    'NetworkSegment': networkSegment,
    'NodeName': nodeName,
    'NodeType': nodeType,
  };
}

// File 子类
class FileInfo {
  final String description;
  final int guid;
  final String layer;
  final String model;

  FileInfo({
    required this.description,
    required this.guid,
    required this.layer,
    required this.model,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) => FileInfo(
    description: json['Description'] as String,
    guid: json['Guid'] as int,
    layer: json['Layer'] as String,
    model: json['Model'] as String,
  );

  Map<String, dynamic> toJson() => {
    'Description': description,
    'Guid': guid,
    'Layer': layer,
    'Model': model,
  };
}

// SystemConfiguration 子类
class SystemConfiguration {
  final LANMember lanMember;
  final LANPrimary lanPrimary;
  final Radio radio;
  final Map<String, dynamic> starLink; // 空对象，用 Map 表示

  SystemConfiguration({
    required this.lanMember,
    required this.lanPrimary,
    required this.radio,
    required this.starLink,
  });

  factory SystemConfiguration.fromJson(Map<String, dynamic> json) {
    return SystemConfiguration(
      lanMember: LANMember.fromJson(json['LANMember'] as Map<String, dynamic>),
      lanPrimary: LANPrimary.fromJson(
        json['LANPrimary'] as Map<String, dynamic>,
      ),
      radio: Radio.fromJson(json['Radio'] as Map<String, dynamic>),
      starLink: json['StarLink'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'LANMember': lanMember.toJson(),
    'LANPrimary': lanPrimary.toJson(),
    'Radio': radio.toJson(),
    'StarLink': starLink,
  };
}

// LANMember 子类
class LANMember {
  final List<String> ccu; // CCU 列表

  LANMember({required this.ccu});

  factory LANMember.fromJson(Map<String, dynamic> json) {
    final ccuList = json['CCU'] as List<dynamic>?;
    return LANMember(ccu: ccuList?.map((e) => e as String).toList() ?? []);
  }

  Map<String, dynamic> toJson() => {'CCU': ccu};
}

// LANPrimary 子类
class LANPrimary {
  final List<String> server;

  LANPrimary({required this.server});

  factory LANPrimary.fromJson(Map<String, dynamic> json) {
    final serverList = json['Server'] as List<dynamic>?;
    return LANPrimary(
      server: serverList?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {'Server': server};
}

// Radio 子类
class Radio {
  final List<String> mmr200;

  Radio({required this.mmr200});

  factory Radio.fromJson(Map<String, dynamic> json) {
    final mmrList = json['MMR200'] as List<dynamic>?;
    return Radio(mmr200: mmrList?.map((e) => e as String).toList() ?? []);
  }

  Map<String, dynamic> toJson() => {'MMR200': mmr200};
}
