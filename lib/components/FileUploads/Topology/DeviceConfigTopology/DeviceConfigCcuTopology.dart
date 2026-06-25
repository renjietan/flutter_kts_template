class DeviceConfigCcuTopology {
  AudioBoardIpConfig? audioBoardIpConfig;
  ControlBoardIpConfig? controlBoardIpConfig;
  Dap? dap;
  // HfRadio? hfRadio;
  MediaBoardIpConfig? mediaBoardIpConfig;
  MmrParam? mmrParam;
  NtpTimeSync? ntpTimeSync;
  TransTable? transTable;

  DeviceConfigCcuTopology({
    this.audioBoardIpConfig,
    this.controlBoardIpConfig,
    this.dap,
    // this.hfRadio,
    this.mediaBoardIpConfig,
    this.mmrParam,
    this.ntpTimeSync,
    this.transTable,
  });

  DeviceConfigCcuTopology.fromJson(Map<String, dynamic> json) {
    audioBoardIpConfig = json['audioBoardIpConfig'] != null
        ? AudioBoardIpConfig.fromJson(json['audioBoardIpConfig'])
        : null;
    controlBoardIpConfig = json['controlBoardIpConfig'] != null
        ? ControlBoardIpConfig.fromJson(json['controlBoardIpConfig'])
        : null;
    dap = json['dap'] != null ? Dap.fromJson(json['dap']) : null;
    // hfRadio = json['hfRadio'] != null
    //     ?  HfRadio.fromJson(json['hfRadio'])
    //     : null;
    mediaBoardIpConfig = json['mediaBoardIpConfig'] != null
        ? MediaBoardIpConfig.fromJson(json['mediaBoardIpConfig'])
        : null;
    mmrParam = json['mmrParam'] != null
        ? MmrParam.fromJson(json['mmrParam'])
        : null;
    ntpTimeSync = json['ntpTimeSync'] != null
        ? NtpTimeSync.fromJson(json['ntpTimeSync'])
        : null;
    transTable = json['transTable'] != null
        ? TransTable.fromJson(json['transTable'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (audioBoardIpConfig != null) {
      data['audioBoardIpConfig'] = audioBoardIpConfig!.toJson();
    }
    if (controlBoardIpConfig != null) {
      data['controlBoardIpConfig'] = controlBoardIpConfig!.toJson();
    }
    if (dap != null) {
      data['dap'] = dap!.toJson();
    }
    // if (hfRadio != null) {
    //   data['hfRadio'] = hfRadio!.toJson();
    // }
    if (mediaBoardIpConfig != null) {
      data['mediaBoardIpConfig'] = mediaBoardIpConfig!.toJson();
    }
    if (mmrParam != null) {
      data['mmrParam'] = mmrParam!.toJson();
    }
    if (ntpTimeSync != null) {
      data['ntpTimeSync'] = ntpTimeSync!.toJson();
    }
    if (transTable != null) {
      data['transTable'] = transTable!.toJson();
    }
    return data;
  }
}

class AudioBoardIpConfig {
  String? name;
  AudioBoardIpConfigResult? audioBoardIpConfigResult;

  AudioBoardIpConfig({this.name, this.audioBoardIpConfigResult});

  AudioBoardIpConfig.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    audioBoardIpConfigResult = json['result'] != null
        ? AudioBoardIpConfigResult.fromJson(json['result'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (audioBoardIpConfigResult != null) {
      data['result'] = audioBoardIpConfigResult!.toJson();
    }
    return data;
  }
}

class AudioBoardIpConfigResult {
  String? ip;
  String? mask;

  AudioBoardIpConfigResult({this.ip, this.mask});

  AudioBoardIpConfigResult.fromJson(Map<String, dynamic> json) {
    ip = json['ip'];
    mask = json['mask'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ip'] = ip;
    data['mask'] = mask;
    return data;
  }
}

class ControlBoardIpConfig {
  String? name;
  ControlBoardIpConfigResult? controlBoardIpConfigResult;

  ControlBoardIpConfig({this.name, this.controlBoardIpConfigResult});

  ControlBoardIpConfig.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    controlBoardIpConfigResult = json['result'] != null
        ? ControlBoardIpConfigResult.fromJson(json['result'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (controlBoardIpConfigResult != null) {
      data['result'] = controlBoardIpConfigResult!.toJson();
    }
    return data;
  }
}

class ControlBoardIpConfigResult {
  List<Gws>? gws;
  String? ip1;
  String? ip2;
  String? mask1;
  String? mask2;

  ControlBoardIpConfigResult({
    this.gws,
    this.ip1,
    this.ip2,
    this.mask1,
    this.mask2,
  });

  ControlBoardIpConfigResult.fromJson(Map<String, dynamic> json) {
    if (json['gws'] != null) {
      gws = <Gws>[];
      json['gws'].forEach((v) {
        gws!.add(Gws.fromJson(v));
      });
    }
    ip1 = json['ip1'];
    ip2 = json['ip2'];
    mask1 = json['mask1'];
    mask2 = json['mask2'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (gws != null) {
      data['gws'] = gws!.map((v) => v.toJson()).toList();
    }
    data['ip1'] = ip1;
    data['ip2'] = ip2;
    data['mask1'] = mask1;
    data['mask2'] = mask2;
    return data;
  }
}

class Gws {
  int? isRouteAddGw;
  int? routeDev;
  String? routeDstIP;
  String? routeGw;
  String? routeMask;

  Gws({
    this.isRouteAddGw,
    this.routeDev,
    this.routeDstIP,
    this.routeGw,
    this.routeMask,
  });

  Gws.fromJson(Map<String, dynamic> json) {
    isRouteAddGw = json['isRouteAddGw'];
    routeDev = json['routeDev'];
    routeDstIP = json['routeDstIP'];
    routeGw = json['routeGw'];
    routeMask = json['routeMask'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isRouteAddGw'] = isRouteAddGw;
    data['routeDev'] = routeDev;
    data['routeDstIP'] = routeDstIP;
    data['routeGw'] = routeGw;
    data['routeMask'] = routeMask;
    return data;
  }
}

class Dap {
  String? name;
  List<DapResult>? dapResult;

  Dap({this.name, this.dapResult});

  Dap.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    if (json['result'] != null) {
      dapResult = <DapResult>[];
      json['result'].forEach((v) {
        dapResult!.add(DapResult.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (dapResult != null) {
      data['result'] = dapResult!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DapResult {
  String? dapUid;
  String? name;

  DapResult({this.dapUid, this.name});

  DapResult.fromJson(Map<String, dynamic> json) {
    dapUid = json['dapUid'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['dapUid'] = dapUid;
    data['name'] = name;
    return data;
  }
}

// class HfRadio {
//   String? name;
//   List<Null>? hfRadioResult;
//
//   HfRadio({this.name, this.hfRadioResult});
//
//   HfRadio.fromJson(Map<String, dynamic> json) {
//     name = json['name'];
//     if (json['hfRadioResult'] != null) {
//       hfRadioResult = <Null>[];
//       json['hfRadioResult'].forEach((v) {
//         hfRadioResult!.add(v);
//       });
//     }
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data =  Map<String, dynamic>();
//     data['name'] = this.name;
//     if (this.hfRadioResult != null) {
//       data['hfRadioResult'] = this.hfRadioResult!
//           .map((v) => v.toJson())
//           .toList();
//     }
//     return data;
//   }
// }

class MediaBoardIpConfig {
  String? name;
  AudioBoardIpConfigResult? mediaBoardIpConfigResult;

  MediaBoardIpConfig({this.name, this.mediaBoardIpConfigResult});

  MediaBoardIpConfig.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    mediaBoardIpConfigResult = json['result'] != null
        ? AudioBoardIpConfigResult.fromJson(json['result'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (mediaBoardIpConfigResult != null) {
      data['result'] = mediaBoardIpConfigResult!.toJson();
    }
    return data;
  }
}

class MmrParam {
  String? name;
  MmrParamResult? mmrParamResult;

  MmrParam({this.name, this.mmrParamResult});

  MmrParam.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    mmrParamResult = json['result'] != null
        ? MmrParamResult.fromJson(json['result'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (mmrParamResult != null) {
      data['result'] = mmrParamResult!.toJson();
    }
    return data;
  }
}

class MmrParamResult {
  List<MmrArray>? mmrArray;

  MmrParamResult({this.mmrArray});

  MmrParamResult.fromJson(Map<String, dynamic> json) {
    if (json['mmrArray'] != null) {
      mmrArray = <MmrArray>[];
      json['mmrArray'].forEach((v) {
        mmrArray!.add(MmrArray.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (mmrArray != null) {
      data['mmrArray'] = mmrArray!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MmrArray {
  int? id;
  String? ip;

  MmrArray({this.id, this.ip});

  MmrArray.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    ip = json['ip'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['ip'] = ip;
    return data;
  }
}

class NtpTimeSync {
  String? name;
  NtpTimeSyncResult? ntpTimeSyncResult;

  NtpTimeSync({this.name, this.ntpTimeSyncResult});

  NtpTimeSync.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    ntpTimeSyncResult = json['result'] != null
        ? NtpTimeSyncResult.fromJson(json['result'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (ntpTimeSyncResult != null) {
      data['result'] = ntpTimeSyncResult!.toJson();
    }
    return data;
  }
}

class NtpTimeSyncResult {
  int? ifOpen;
  int? interval;
  String? ip;

  NtpTimeSyncResult({this.ifOpen, this.interval, this.ip});

  NtpTimeSyncResult.fromJson(Map<String, dynamic> json) {
    ifOpen = json['ifOpen'];
    interval = json['interval'];
    ip = json['ip'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ifOpen'] = ifOpen;
    data['interval'] = interval;
    data['ip'] = ip;
    return data;
  }
}

class TransTable {
  List<TransTableResult>? transTableResult;

  TransTable({this.transTableResult});

  TransTable.fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      transTableResult = <TransTableResult>[];
      json['result'].forEach((v) {
        transTableResult!.add(TransTableResult.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (transTableResult != null) {
      data['result'] = transTableResult!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TransTableResult {
  List<Table>? table;
  int? type;

  TransTableResult({this.table, this.type});

  TransTableResult.fromJson(Map<String, dynamic> json) {
    if (json['table'] != null) {
      table = <Table>[];
      json['table'].forEach((v) {
        table!.add(Table.fromJson(v));
      });
    }
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (table != null) {
      data['table'] = table!.map((v) => v.toJson()).toList();
    }
    data['type'] = type;
    return data;
  }
}

class Table {
  String? dstNum;
  String? dstReserve;
  String? dstSlfCode;
  int? dstType;
  int? index;
  String? srcNum;
  int? srcReserve;
  int? srcType;

  Table({
    this.dstNum,
    this.dstReserve,
    this.dstSlfCode,
    this.dstType,
    this.index,
    this.srcNum,
    this.srcReserve,
    this.srcType,
  });

  Table.fromJson(Map<String, dynamic> json) {
    dstNum = json['dstNum'];
    dstReserve = json['dstReserve'];
    dstSlfCode = json['dstSlfCode'];
    dstType = json['dstType'];
    index = json['index'];
    srcNum = json['srcNum'];
    srcReserve = json['srcReserve'];
    srcType = json['srcType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['dstNum'] = dstNum;
    data['dstReserve'] = dstReserve;
    data['dstSlfCode'] = dstSlfCode;
    data['dstType'] = dstType;
    data['index'] = index;
    data['srcNum'] = srcNum;
    data['srcReserve'] = srcReserve;
    data['srcType'] = srcType;
    return data;
  }
}
