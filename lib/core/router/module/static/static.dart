import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import '../base.dart';

class StaticRoutes extends BaseRouteGroup {
  @override
  String get prefix => '/';

  @override
  Router register(Router router) {
    // 使用 shelf_static 中间件托管静态文件
    final staticHandler = createStaticHandler(
      'public',
      defaultDocument: 'index.html',
      listDirectories: false,
    );

    // 将所有 GET 请求（非 API 路径）指向静态文件处理器
    // 注意：由于 cascade 处理顺序，API 请求会优先匹配更具体的路由
    router.get('/<ignored|.*>', (Request request) {
      return staticHandler(request);
    });

    return router;
  }
}
