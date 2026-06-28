
import 'package:flutter_kts_template/core/controller/user/user.controller.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../utils/response.dart';
import '../base.dart';


class UserRoutes extends BaseRouteGroup {
  @override
  String get prefix => '/users';

  @override
  Router register(Router router) {
    // GET /api/users
    // router.get('/', (Request request) {
    //   final userList = ['Alice', 'Bob', 'Charlie'];
    //   return ApiResponse.success(data: {'users': userList, 'total': 3});
    // });
    router.get('/', UserController.getList);

    // GET /api/users/<id>
    router.get('/<id>', (Request request, String id) {
      // 模拟用户不存在的情况
      if (id == '999') {
        return ApiResponse.notFound(message: 'User not found');
      }
      return ApiResponse.success(data: {'userId': id, 'name': 'User $id'});
    });

    // POST /api/users
    // router.post('/', (Request request) {
    //   final data = request.context["body"];
    //   return ApiResponse.success(data: data, message: 'User created');
    // });
    router.post('/', UserController.create);

    // PUT /api/users/<id>
    router.put('/<id>', (Request request, String id) async {
      return ApiResponse.success(data: {'userId': id, 'updated': request.context["params"]});
    });

    // DELETE /api/users/<id>
    router.delete('/<id>', (Request request, String id) {
      return ApiResponse.success(data: {'deletedId': id});
    });

    return router;
  }
}