import 'package:shelf_router/shelf_router.dart';

import '../../../controller/upload/upload.controller.dart';
import '../base.dart';

class UploadRoutes extends BaseRouteGroup {
  @override
  String get prefix => '/uploadServer';

  @override
  Router register(Router router) {
    router.post('/zip', UploadController.uploadHandler);
    return router;
  }
}
