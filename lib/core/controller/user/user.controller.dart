import 'package:flutter_kts_template/core/utils/time.dart';
import 'package:shelf/shelf.dart';

import '../../databaseManager/databaseManager.dart';
import '../../entities/book/bookEntity.dart';
import '../../entities/user/userEntity.dart';
import '../../utils/response.dart';

class UserController {
  static Response getList(Request request) {
    final db = DatabaseManager.instance;
    List<UserEntity> users = db.getAll<UserEntity>();
    return ApiResponse.success(data: {'list': users.toList(), 'total': 3});
  }

  static Future<Response> create(Request request) async {
    final db = DatabaseManager.instance;
    final Map<String, dynamic> params =
        request.context["params"] as Map<String, dynamic>;
    // 通过 异步 的方式 运行在后台，防止阻塞UI
    int id = await db.writeTransactionAsync((store, _params) {
      final userBox = store.box<UserEntity>();
      _params["updatedAt"] = parseDateTime(DateTime.now());
      UserEntity user = UserEntity.fromJson(params);
      int id = userBox.put(user);
      final bookBox = store.box<BookEntity>();
      Map<String, dynamic> bookData = _params["book"];
      bookData["authorId"] = id;
      BookEntity book = BookEntity.fromJson(bookData);
      bookBox.put(book);
      // writeTransactionAsync 内部通过 SendPort 将回调结果从后台 Isolate 传回主 Isolate，
      // 而 SendPort 只能发送“可发送对象”（如基础类型、简单 List/Map，不含 Stream 或闭包）。
      // ApiResponse.success 返回的是一个 shelf.Response，
      // 它内部包含了 Stream（响应体的流），这违反了传递限制，因此抛出 unsendable object 异常。
      return id;
    }, params);
    return ApiResponse.success(data: id, message: "新增成功");
  }
}
