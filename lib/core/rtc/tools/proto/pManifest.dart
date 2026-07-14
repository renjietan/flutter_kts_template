import 'dart:typed_data';

import 'byteTools.dart';
import 'pModel.dart';
import 'pTools.dart';

class ProtoManifest {
  static final List<ProtoModel> baseModel = [
    ProtoModel(field: "SrcID", data: Uint8List.fromList([0xee])),
    ProtoModel(field: "DstID", data: Uint8List.fromList([0xee])),
    ProtoModel(
      field: "Length",
      data: Uint8List.fromList([0x00, 0x00]),
      type: ProtoModelTypeEnum.length,
    ),
    ProtoModel(
      field: "CRC",
      data: Uint8List.fromList([0x00, 0x00]),
      type: ProtoModelTypeEnum.uInts,
    ),
    ProtoModel(field: "Version", data: Uint8List.fromList([0x02])),
    ProtoModel(field: "UserID", data: Uint8List.fromList([0x00])),
  ];

  static Uint8List login(String username) {
    Uint8List usernameLen = ByteTools.int2UintList(username.length, byteLen: 1);
    Uint8List usernameByte = ByteTools.str2UintList(username, unitSize: 2);
    ProtoModels models = ProtoModels(
      name: "login",
      list: [
        ...baseModel,
        ProtoModel(field: "SAP", data: Uint8List.fromList([0x01])),
        ProtoModel(field: "OptCode", data: Uint8List.fromList([0x01])),
        ProtoModel(
          field: "Size",
          data: usernameLen,
          type: ProtoModelTypeEnum.int,
        ),
        ProtoModel(
          field: "UserName",
          data: usernameByte,
          type: ProtoModelTypeEnum.string2,
        ),
      ],
    );
    Uint8List res = ProtoTools.models2Uint8List(models);
    return res;
  }

  // 登录
  static Uint8List loginWithPing(String username) {
    // 登录-心跳
    Uint8List superviseInterval = ByteTools.int2UintList(3000, byteLen: 4);
    Uint8List superviseCnt = ByteTools.int2UintList(100, byteLen: 2);
    Uint8List usernameLen = ByteTools.int2UintList(username.length, byteLen: 1);
    Uint8List usernameByte = ByteTools.str2UintList(username, unitSize: 2);
    ProtoModels models = ProtoModels(
      name: "loginWithPing",
      list: [
        ...baseModel,
        ProtoModel(field: "SAP", data: Uint8List.fromList([0x01])),
        ProtoModel(field: "OptCode", data: Uint8List.fromList([0x05])),
        ProtoModel(
          field: "SuperviseInterval",
          data: superviseInterval,
          type: ProtoModelTypeEnum.int,
        ),
        ProtoModel(
          field: "SuperviseCnt",
          data: superviseCnt,
          type: ProtoModelTypeEnum.int,
        ),
        ProtoModel(
          field: "Size",
          data: usernameLen,
          type: ProtoModelTypeEnum.int,
        ),
        ProtoModel(
          field: "UserName",
          data: usernameByte,
          type: ProtoModelTypeEnum.string2,
        ),
      ],
    );
    Uint8List res = ProtoTools.models2Uint8List(models);
    return res;
  }

  // 心跳
  static Uint8List ping() {
    ProtoModels models = ProtoModels(
      name: "ping",
      list: [
        ...baseModel,
        ProtoModel(field: "SAP", data: Uint8List.fromList([0x01])),
        ProtoModel(field: "OptCode", data: Uint8List.fromList([0x03])),
        ProtoModel(field: "Status", data: Uint8List.fromList([0x00])),
      ],
    );
    Uint8List res = ProtoTools.models2Uint8List(models);
    return res;
  }

  // 文件传输: 1、先发送文件头请求
  // packetCnt: 文件分发个数
  // fileSize: 文件长度
  // fileName: 文件名称
  static Uint8List fileHeader({
    required String fileName,
    required int fileSize,
    required int packetCnt,
  }) {
    Uint8List packetCntByte = ByteTools.int2UintList(packetCnt, byteLen: 2);
    Uint8List fileSizeBytes = ByteTools.int2UintList(fileSize, byteLen: 4);
    Uint8List nameLenBytes = ByteTools.int2UintList(
      fileName.length,
      byteLen: 4,
    );
    Uint8List fileNameBytes = ByteTools.str2UintList(fileName);
    ProtoModels models = ProtoModels(
      name: "fileHeader",
      list: [
        ...baseModel,
        ProtoModel(field: "SAP", data: Uint8List.fromList([0x04])),
        ProtoModel(field: "OptCode", data: Uint8List.fromList([0x03])),
        ProtoModel(field: "FileCRC", data: Uint8List.fromList([0x00])),
        ProtoModel(
          field: "PacketCnt",
          data: packetCntByte,
          type: ProtoModelTypeEnum.int,
        ),
        ProtoModel(
          field: "FileSize",
          data: fileSizeBytes,
          type: ProtoModelTypeEnum.int,
        ),
        ProtoModel(
          field: "NameLen",
          data: nameLenBytes,
          type: ProtoModelTypeEnum.int,
        ),
        ProtoModel(
          field: "FileName",
          data: fileNameBytes,
          type: ProtoModelTypeEnum.string,
        ),
      ],
    );
    Uint8List res = ProtoTools.models2Uint8List(models);
    return res;
  }

  // 文件传输: 2、发送文件内容
  // packetSize 每一包的大小
  // data: 包数据
  static List<Uint8List> fileData({
    required int packetSize,
    required Uint8List data,
  }) {
    List<Uint8List> packetContents = ByteTools.chunkBytes(
      data,
      chunkSize: packetSize,
    );
    int count = 0;
    return packetContents.fold<List<Uint8List>>([], (cur, pre) {
      Uint8List packetNumBytes = ByteTools.int2UintList(count, byteLen: 2);
      Uint8List packetSizeBytes = ByteTools.int2UintList(
        packetSize,
        byteLen: 2,
      );
      ProtoModels models = ProtoModels(
        name: "fileData",
        list: [
          ...baseModel,
          ProtoModel(field: "SAP", data: Uint8List.fromList([0x04])),
          ProtoModel(field: "OptCode", data: Uint8List.fromList([0x03])),
          ProtoModel(field: "PacketCrc", data: Uint8List.fromList([0x00])),
          ProtoModel(
            field: "PacketNum",
            data: packetNumBytes,
            type: ProtoModelTypeEnum.int,
          ),
          ProtoModel(
            field: "PacketSize",
            data: packetSizeBytes,
            type: ProtoModelTypeEnum.int,
          ),
          ProtoModel(field: "Data", data: pre),
        ],
      );
      Uint8List temp = ProtoTools.models2Uint8List(models); // 单包的码流
      cur.add(temp);
      count++;
      return cur;
    });
  }
}
