import 'package:flutter_kts_template/core/entities/keyLoaderDetails/keyLoaderDetailsEntity.dart';
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
    List<KeyLoadersEntity> parent = db
        .box<KeyLoadersEntity>()
        .query()
        .order(KeyLoadersEntity_.id, flags: Order.descending)
        .build()
        .find();
    List<KeyLoaderDetailsEntity> children = db
        .box<KeyLoaderDetailsEntity>()
        .query()
        .order(KeyLoaderDetailsEntity_.id, flags: Order.descending)
        .build()
        .find();
    List res = parent.fold([], (cur, pre) {
      var temp = {
        "id": pre.id,
        "name": pre.name,
        "createdAt": parseDateTime(pre.createdAt),
        "updatedAt": parseDateTime(pre.updatedAt),
        "children": [],
      };
      temp["children"] = children.fold<List>([], (c, p) {
        var temp = {
          "id": p.id,
          "netNodePackageName": p.netNodePackageName,
          "dcPackageName": p.dcPackageName,
          "keyLoaderId": p.keyLoaderId,
          "consumer": p.consumer,
          "radioId": p.radioId,
          "createdAt": parseDateTime(p.createdAt),
          "updatedAt": parseDateTime(p.updatedAt),
        };
        c.add(temp);
        return c;
      });
      cur.add(temp);
      return cur;
    });
    return ApiResponse.success(data: {'list': res, 'total': parent.length});
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
    // 通过 异步 的方式 运行在后台，防止阻塞UI
    final box = db.box<KeyLoadersEntity>();

    KeyLoadersEntity? entities = box.get(uId);
    if (entities == null) {
      return ApiResponse.error(message: t.common.noData);
    }
    KeyLoadersEntity? tempEntries = box
        .query(
          KeyLoadersEntity_.id
              .notEquals(uId)
              .and(KeyLoadersEntity_.name.equals(params["name"])),
        )
        .build()
        .findFirst();
    if (tempEntries != null) {
      return ApiResponse.error(message: t.entity.sameName);
    }
    entities.name = params["name"];
    entities.updatedAt = DateTime.now();
    int id = box.put(entities);
    return ApiResponse.success(data: id, message: t.common.OperationSuccess);
  }

  static Response getDetails(Request request) {
    final db = DatabaseManager.instance;
    int uId = getId(request.context["path"] as List<String>?);
    List<KeyLoaderDetailsEntity> data = db
        .box<KeyLoaderDetailsEntity>()
        .query(KeyLoaderDetailsEntity_.keyLoaderId.equals(uId))
        .order(KeyLoaderDetailsEntity_.id, flags: Order.descending)
        .build()
        .find();
    return ApiResponse.success(data: {'list': data, 'total': data.length});
  }

  static Future<Response> updateDetails(Request request) async {
    final db = DatabaseManager.instance;
    final Map<String, dynamic> params =
        request.context["params"] as Map<String, dynamic>;
    int uId = getId(request.context["path"] as List<String>?);
    final box = db.box<KeyLoaderDetailsEntity>();
    final query = box
        .query(KeyLoaderDetailsEntity_.keyLoaderId.equals(uId))
        .build();
    query.remove();
    List<String> dcPackageNames = params["dcPackageNames"].toString().split(
      ",",
    );
    List<KeyLoaderDetailsEntity> entitles = [];
    for (var dcPackageName in dcPackageNames) {
      KeyLoaderDetailsEntity temp = KeyLoaderDetailsEntity(
        keyLoaderId: uId,
        netNodePackageName: params["netNodePackageName"],
        dcPackageName: dcPackageName,
        consumer: params["consumer"],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      entitles.add(temp);
    }
    List<int> ids = box.putMany(entitles);
    return ApiResponse.success(data: ids, message: t.common.OperationSuccess);
  }

  static Future<Response> delete(Request request) async {
    final db = DatabaseManager.instance;
    List<int> ids = getIds(request.context["path"] as List<String>?);
    var box = db.box<KeyLoadersEntity>();
    int data = box.removeMany(ids);
    return ApiResponse.success(data: data, message: t.common.OperationSuccess);
  }
}
