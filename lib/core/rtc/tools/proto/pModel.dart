import 'dart:typed_data';

import 'byteTools.dart';

class ProtoModels {
  final String name;
  final List<ProtoModel> list;
  ProtoModels({required this.name, required this.list});

  @override
  String toString() {
    var str = list.fold("", (cur, pre) {
      cur = cur + pre.toString();
      return cur;
    });
    str =
        "========================== $name ============================\n" + str;
    return str;
  }
}

/*
1、[file]   代表 List<Uint8List> 中是 文件bytes，需要分包
2、[string] 代表 8位 List<Uint8List> 可转字符串
  [string2] 代表 16位 List<Uint8List> 可转字符串
  [string4] 代表 32位 List<Uint8List> 可转字符串
  [string8] 代表 64位 List<Uint8List> 可转字符串
2、[int]    代表List<Uint8List> 可转数字
3、[length] 代表 后续的字节长度 需要 累加到 这个字段
4、[uInts]  代表 它是纯 List<Uint8List>，不可转字符串，也不是文本内容
*/
enum ProtoModelTypeEnum {
  file,
  string,
  string2,
  string4,
  string8,
  int,
  length,
  uInts,
}

class ProtoModel {
  final String field;
  final Uint8List data;
  final ProtoModelTypeEnum type;
  final Endian endian;

  ProtoModel({
    required this.field,
    Uint8List? data,
    this.type = ProtoModelTypeEnum.uInts,
    this.endian = ByteTools.defaultEndian,
  }) : data = data ?? Uint8List.fromList([]);

  @override
  String toString() {
    String bytesStr = ByteTools.uIntList2uIntListStr(data);
    var byteValue = "";
    if (type == ProtoModelTypeEnum.file) {
      byteValue = "${type.toString()} 不转换";
    } else if (type == ProtoModelTypeEnum.uInts) {
      byteValue = "${type.toString()} 不转换";
    } else if (type == ProtoModelTypeEnum.string) {
      byteValue = ByteTools.uIntList2str(data, unitSize: 1);
    } else if (type == ProtoModelTypeEnum.string2) {
      byteValue = ByteTools.uIntList2str(data, unitSize: 2);
    } else if (type == ProtoModelTypeEnum.string4) {
      byteValue = ByteTools.uIntList2str(data, unitSize: 4);
    } else if (type == ProtoModelTypeEnum.string8) {
      byteValue = ByteTools.uIntList2str(data, unitSize: 8);
    } else if (type == ProtoModelTypeEnum.length ||
        type == ProtoModelTypeEnum.int) {
      int res = ByteTools.uIntList2Int(data, byteLen: data.length);
      byteValue = "$res";
    }
    return "ProtoModel{\n"
        "  field: $field\n"
        "  type: ${type.toString()}\n"
        "  endian: ${endian == Endian.little ? 'Endian.little' : "Endian.big"}\n"
        "  List<int>: $data\n"
        "  bytes: $bytesStr\n"
        "  byteValue: $byteValue\n"
        "}\n";
  }
}
