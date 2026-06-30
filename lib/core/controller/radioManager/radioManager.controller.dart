import 'package:flutter_kts_template/core/controller/radioManager/radioManager.dto.dart';
import 'package:flutter_kts_template/objectbox.g.dart';
import 'package:shelf/shelf.dart';

import '../../../i18n/handle/translations.g.dart';
import '../../databaseManager/databaseManager.dart';
import '../../entities/radios/radiosEntity.dart';
import '../../utils/response.dart';
import '../../utils/time.dart';
import '../../utils/url.dart';

class RadioManagerController {
  static Response getList(Request request) {
    final db = DatabaseManager.instance;
    final RadioManagerDto params = RadioManagerDto.fromJson(
      request.context["params"] as Map<String, dynamic>,
    );
    try {
      params.validateOrThrow();
      final condition = <Condition<RadiosEntity>>[];
      if (params.keyword.isNotEmpty) {
        final keyword = params.keyword;
        condition.add(
          RadiosEntity_.alias
              .contains(keyword)
              .or(RadiosEntity_.consumer.contains(keyword))
              .or(RadiosEntity_.location.contains(keyword))
              .or(RadiosEntity_.sn.contains(keyword)),
        );
      }
      final query = db
          .box<RadiosEntity>()
          .query(condition.isEmpty ? null : condition.first)
          .order(RadiosEntity_.updatedAt, flags: Order.descending)
          .build();
      var count = query.count();
      if (params.pageLimit != 0 && params.pageNum != 0) {
        query.offset = params.offset;
        query.limit = params.pageLimit;
      }
      var res = query.find();
      return ApiResponse.success(data: {'list': res.toList(), 'total': count});
    } catch (err) {
      return ApiResponse.error(message: err.toString());
    }
  }

  static Future<Response> create(Request request) async {
    final db = DatabaseManager.instance;
    final Map<String, dynamic> params =
        request.context["params"] as Map<String, dynamic>;
    params["updatedAt"] = parseDateTime(DateTime.now());
    // 通过 异步 的方式 运行在后台，防止阻塞UI
    final radiosBox = db.box<RadiosEntity>();
    RadiosEntity radio = RadiosEntity.fromJson(params);
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
    final radiosBox = db.box<RadiosEntity>();

    RadiosEntity? radiosEntity = radiosBox.get(uId);
    if (radiosEntity == null) {
      return ApiResponse.error(message: t.common.noData);
    }
    radiosEntity = RadiosEntity.fromJson(params);
    int id = radiosBox.put(radiosEntity);
    return ApiResponse.success(data: id, message: t.common.OperationSuccess);
  }

  static Future<Response> delete(Request request) async {
    final db = DatabaseManager.instance;
    List<int> ids = getIds(request.context["path"] as List<String>?);
    var box = db.box<RadiosEntity>();
    int data = box.removeMany(ids);
    return ApiResponse.success(data: data, message: t.common.OperationSuccess);
  }
}
