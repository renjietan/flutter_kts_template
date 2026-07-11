import 'package:flutter_kts_template/core/entities/keyLoaders/keyLoadersEntity.dart';
import 'package:flutter_kts_template/objectbox.g.dart';
import 'package:shelf/shelf.dart';

import '../../../i18n/handle/translations.g.dart';
import '../../databaseManager/databaseManager.dart';
import '../../utils/response.dart';
import '../../utils/time.dart';
import '../../utils/url.dart';

class KeyLoadersController {
  static Response getAll(Request request) {
    final db = DatabaseManager.instance;
    var query = db
        .box<KeyLoadersEntity>()
        .query()
        .order(KeyLoadersEntity_.id, flags: Order.descending)
        .build();
    List<KeyLoadersEntity> res = query.find();
    var count = query.count();
    return ApiResponse.success(data: {'list': res.toList(), 'total': count});
  }

  static Future<Response> create(Request request) async {
    final db = DatabaseManager.instance;
    final Map<String, dynamic> params =
        request.context["params"] as Map<String, dynamic>;
    params["createdAt"] = parseDateTime(DateTime.now());
    final box = db.box<KeyLoadersEntity>();
    KeyLoadersEntity? tempEntries = box
        .query(KeyLoadersEntity_.name.equals(params["name"]))
        .build()
        .findFirst();
    if (tempEntries != null) {
      return ApiResponse.error(message: t.entity.sameName);
    }
    KeyLoadersEntity data = KeyLoadersEntity.fromJson(params);
    int id = box.put(data);
    return ApiResponse.success(data: id, message: t.common.OperationSuccess);
  }

  static Future<Response> update(Request request) async {
    final db = DatabaseManager.instance;
    final Map<String, dynamic> params =
        request.context["params"] as Map<String, dynamic>;
    int uId = getId(request.context["path"] as List<String>?);
    params["id"] = uId;
    params["updatedAt"] = parseDateTime(DateTime.now());
    // 通过 异步 的方式 运行在后台，防止阻塞UI
    final box = db.box<KeyLoadersEntity>();

    KeyLoadersEntity? entities = box.get(uId);
    if (entities == null) {
      return ApiResponse.error(message: t.common.noData);
    }
    KeyLoadersEntity? tempEntries = box
        .query(
          KeyLoadersEntity_.id
              .notEquals(params["id"])
              .and(KeyLoadersEntity_.name.equals(params["name"])),
        )
        .build()
        .findFirst();
    if (tempEntries != null) {
      return ApiResponse.error(message: t.entity.sameName);
    }
    params["createdAt"] = parseDateTime(entities.createdAt);
    entities = KeyLoadersEntity.fromJson(params);
    int id = box.put(entities);
    return ApiResponse.success(data: id, message: t.common.OperationSuccess);
  }

  static Future<Response> delete(Request request) async {
    final db = DatabaseManager.instance;
    List<int> ids = getIds(request.context["path"] as List<String>?);
    var box = db.box<KeyLoadersEntity>();
    int data = box.removeMany(ids);
    return ApiResponse.success(data: data, message: t.common.OperationSuccess);
  }
}
