import 'package:flutter_kts_template/core/entities/bindConfig/bindConfigEntity.dart';
import 'package:flutter_kts_template/objectbox.g.dart';
import 'package:shelf/shelf.dart';

import '../../../i18n/handle/translations.g.dart';
import '../../databaseManager/databaseManager.dart';
import '../../utils/response.dart';
import '../../utils/time.dart';

class BindConfigController {
  static Response getAll(Request request) {
    final db = DatabaseManager.instance;
    var query = db
        .box<BindConfigEntity>()
        .query()
        .order(BindConfigEntity_.id, flags: Order.descending)
        .build();
    List<BindConfigEntity> res = query.find();
    var count = query.count();
    return ApiResponse.success(data: {'list': res.toList(), 'total': count});
  }

  static Future<Response> create(Request request) async {
    final db = DatabaseManager.instance;
    final Map<String, dynamic> params =
        request.context["params"] as Map<String, dynamic>;
    params["createdAt"] = parseDateTime(DateTime.now());
    final box = db.box<BindConfigEntity>();
    box
        .query(BindConfigEntity_.netNodeId.equals(params["netNodeId"]))
        .build()
        .remove();
    BindConfigEntity data = BindConfigEntity.fromJson(params);
    int id = box.put(data);
    return ApiResponse.success(data: id, message: t.common.OperationSuccess);
  }
}
