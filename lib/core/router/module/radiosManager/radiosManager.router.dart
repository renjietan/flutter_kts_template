import 'package:flutter_kts_template/core/controller/radioManager/radioManager.controller.dart';
import 'package:shelf_router/shelf_router.dart';

import '../base.dart';

class RadiosManagerRoutes extends BaseRouteGroup {
  @override
  String get prefix => '/radiosManager';

  @override
  Router register(Router router) {
    router.post('/', RadioManagerController.create);
    router.get('/', RadioManagerController.getList);
    router.put('/<id>', RadioManagerController.update);
    router.delete('/<id>', RadioManagerController.delete);
    return router;
  }
}
