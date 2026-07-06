import 'package:flutter_kts_template/core/controller/keyLoaders/keyLoaders.controller.dart';
import 'package:shelf_router/shelf_router.dart';

import '../base.dart';

class KeyLoadersRoutes extends BaseRouteGroup {
  @override
  String get prefix => '/keyLoaders';

  @override
  Router register(Router router) {
    router.get('/', KeyLoadersController.getAll);
    router.post('/', KeyLoadersController.create);
    router.put('/<id>', KeyLoadersController.update);
    router.delete('/<id>', KeyLoadersController.delete);
    return router;
  }
}
