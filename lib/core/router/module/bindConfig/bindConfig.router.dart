import 'package:flutter_kts_template/core/controller/bindConfig/bindConfig.controller.dart';
import 'package:shelf_router/shelf_router.dart';

import '../base.dart';

class BindConfigRoutes extends BaseRouteGroup {
  @override
  String get prefix => '/bindConfig';

  @override
  Router register(Router router) {
    router.get('/', BindConfigController.getAll);
    router.post('/', BindConfigController.create);
    return router;
  }
}
