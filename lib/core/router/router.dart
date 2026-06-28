import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import '../../logger/logger.dart';
import '../utils/director.dart';
import 'module/base.dart';
import 'module/radiosManager/radiosManager.router.dart';
import 'module/uploads/upload.router.dart';
import 'module/user/user.router.dart';

/// 注册中心：将所有分组路由挂载到根 Router
class RouterRegistry {
  static const String prefix = "/api";

  static Future<Router> init() async {
    final rootRouter = Router();
    // D:\work\flutter\test\flutter_kts_template\uploads
    String uploadPath = await DirectoryManager.instance.getStaticPath();
    final staticHandler = createStaticHandler(
      uploadPath,
      defaultDocument: null, // 不需要默认文档
      listDirectories: false, // 禁止列出目录（安全）
    );
    rootRouter.mount('/uploads', staticHandler);
    GlobalLogger.logInfo("Uploads Path $uploadPath");
    // 所有分组列表（方便统一管理和扩展）
    final List<BaseRouteGroup> routeGroups = [
      UserRoutes(),
      UploadRoutes(),
      RadiosManagerRoutes(),
    ];

    // 遍历每个分组，调用 register 方法并挂载到根路由
    for (final group in routeGroups) {
      final groupRouter = Router();
      group.register(groupRouter);
      String path = "$prefix${group.prefix}";
      rootRouter.mount(path, groupRouter.call);
    }

    return rootRouter;
  }
}
