import 'package:flutter_kts_template/core/controller/keyLoaders/keyLoaders.controller.dart';
import 'package:shelf_router/shelf_router.dart';

import '../base.dart';

class KeyLoadersRoutes extends BaseRouteGroup {
  @override
  String get prefix => '/keyLoaders';

  @override
  Router register(Router router) {
    router.get('/', KeyLoadersController.getAll);
    router.get('/detail/<id>', KeyLoadersController.getDetails);
    router.post('/', KeyLoadersController.create);
    router.put('/update/<id>', KeyLoadersController.update);
    router.put('/updateDetail/<id>', KeyLoadersController.updateDetails);
    router.put('/updateOneDetail/<id>', KeyLoadersController.updateDetail);
    router.delete('/<id>', KeyLoadersController.delete);
    return router;
  }
}
