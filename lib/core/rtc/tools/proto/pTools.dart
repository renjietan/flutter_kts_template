import 'dart:typed_data';

import 'byteTools.dart';
import 'pModel.dart';

class ProtoTools {
  // model 列表 转 Uint8List
  static Uint8List models2Uint8List(ProtoModels models) {
    Map<String, dynamic> acc = {};
    int index = 0;
    int totalBytes = 0;
    BytesBuilder res = models.list.fold<BytesBuilder>(BytesBuilder(), (
      cur,
      pre,
    ) {
      cur.add(pre.data);
      if (pre.type == ProtoModelTypeEnum.length) {
        acc[pre.field] = {
          "start": index,
          "end": index + pre.data.length,
          "value": 0,
        };
      } else {
        acc.forEach((key, value) {
          value["value"] = value["value"] + pre.data.length;
        });
      }
      index++;
      totalBytes = totalBytes + pre.data.length;
      return cur;
    });
    Uint8List r = res.takeBytes();
    acc.forEach((key, value) {
      int start = value["start"];
      int end = value["end"];
      int byteLen = end - start;
      Uint8List v = ByteTools.int2UintList(value["value"], byteLen: byteLen);
      ByteTools.modifyByteByRange(r, start, end, v);
    });
    return r;
  }
}
