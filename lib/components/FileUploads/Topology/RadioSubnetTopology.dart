class RadioSubnetTopology {
  String? accessMode;
  ContactInfo? contactInfo;
  int? encryptFlag;
  File? file;
  int? freqNum;
  int? masterMac;
  String? multicastAddress;
  int? networkID;
  OtherInfo? otherInfo;
  int? radiosCnt;
  List<int>? slotTable;
  String? speed;
  int? waveFormID;

  RadioSubnetTopology({
    this.accessMode,
    this.contactInfo,
    this.encryptFlag,
    this.file,
    this.freqNum,
    this.masterMac,
    this.multicastAddress,
    this.networkID,
    this.otherInfo,
    this.radiosCnt,
    this.slotTable,
    this.speed,
    this.waveFormID,
  });

  RadioSubnetTopology.fromJson(Map<String, dynamic> json) {
    accessMode = json['AccessMode'];
    contactInfo = json['ContactInfo'] != null
        ? new ContactInfo.fromJson(json['ContactInfo'])
        : null;
    encryptFlag = json['EncryptFlag'];
    file = json['File'] != null ? new File.fromJson(json['File']) : null;
    freqNum = json['FreqNum'];
    masterMac = json['MasterMac'];
    multicastAddress = json['MulticastAddress'];
    networkID = json['NetworkID'];
    otherInfo = json['OtherInfo'] != null
        ? new OtherInfo.fromJson(json['OtherInfo'])
        : null;
    radiosCnt = json['RadiosCnt'];
    slotTable = json['SlotTable'].cast<int>();
    speed = json['Speed'];
    waveFormID = json['WaveFormID'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['AccessMode'] = this.accessMode;
    if (this.contactInfo != null) {
      data['ContactInfo'] = this.contactInfo!.toJson();
    }
    data['EncryptFlag'] = this.encryptFlag;
    if (this.file != null) {
      data['File'] = this.file!.toJson();
    }
    data['FreqNum'] = this.freqNum;
    data['MasterMac'] = this.masterMac;
    data['MulticastAddress'] = this.multicastAddress;
    data['NetworkID'] = this.networkID;
    if (this.otherInfo != null) {
      data['OtherInfo'] = this.otherInfo!.toJson();
    }
    data['RadiosCnt'] = this.radiosCnt;
    data['SlotTable'] = this.slotTable;
    data['Speed'] = this.speed;
    data['WaveFormID'] = this.waveFormID;
    return data;
  }
}

class ContactInfo {
  List<Members>? members;

  ContactInfo({this.members});

  ContactInfo.fromJson(Map<String, dynamic> json) {
    if (json['Members'] != null) {
      members = <Members>[];
      json['Members'].forEach((v) {
        members!.add(new Members.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.members != null) {
      data['Members'] = this.members!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Members {
  int? dHCP;
  String? gateway;
  String? group;
  String? iP;
  int? mac;
  String? mask;
  String? name;

  Members({
    this.dHCP,
    this.gateway,
    this.group,
    this.iP,
    this.mac,
    this.mask,
    this.name,
  });

  Members.fromJson(Map<String, dynamic> json) {
    dHCP = json['DHCP'];
    gateway = json['Gateway'];
    group = json['Group'];
    iP = json['IP'];
    mac = json['Mac'];
    mask = json['Mask'];
    name = json['Name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['DHCP'] = this.dHCP;
    data['Gateway'] = this.gateway;
    data['Group'] = this.group;
    data['IP'] = this.iP;
    data['Mac'] = this.mac;
    data['Mask'] = this.mask;
    data['Name'] = this.name;
    return data;
  }
}

class File {
  String? description;
  String? guid;
  String? layer;
  String? waveFormName;
  String? waveFormType;

  File({
    this.description,
    this.guid,
    this.layer,
    this.waveFormName,
    this.waveFormType,
  });

  File.fromJson(Map<String, dynamic> json) {
    description = json['Description'];
    guid = json['Guid'];
    layer = json['Layer'];
    waveFormName = json['WaveFormName'];
    waveFormType = json['WaveFormType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Description'] = this.description;
    data['Guid'] = this.guid;
    data['Layer'] = this.layer;
    data['WaveFormName'] = this.waveFormName;
    data['WaveFormType'] = this.waveFormType;
    return data;
  }
}

class OtherInfo {
  int? id;

  OtherInfo({this.id});

  OtherInfo.fromJson(Map<String, dynamic> json) {
    id = json['Id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Id'] = this.id;
    return data;
  }
}
