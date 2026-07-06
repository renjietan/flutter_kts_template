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
    final radiosBox = db.box<KeyLoadersEntity>();
    KeyLoadersEntity radio = KeyLoadersEntity.fromJson(params);
    int id = radiosBox.put(radio);
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
    final radiosBox = db.box<KeyLoadersEntity>();

    KeyLoadersEntity? radiosEntity = radiosBox.get(uId);
    if (radiosEntity == null) {
      return ApiResponse.error(message: t.common.noData);
    }
    params["createdAt"] = parseDateTime(radiosEntity.createdAt);
    radiosEntity = KeyLoadersEntity.fromJson(params);
    int id = radiosBox.put(radiosEntity);
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
