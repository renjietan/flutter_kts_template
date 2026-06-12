import 'package:shelf_router/shelf_router.dart';

/// 所有路由分组的抽象基类
/// 每个分组类都必须实现 [register] 方法，向传入的 Router 注册路由
abstract class BaseRouteGroup {
  /// 路由前缀，子类可覆盖
  String get prefix => '/';

  /// 注册路由到传入的 router 中
  Router register(Router router);
}