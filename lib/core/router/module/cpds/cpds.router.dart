import 'dart:convert';

import 'package:flutter_kts_template/core/controller/cpds/cpds.controller.dart';
import 'package:flutter_kts_template/core/cpds/service/cpds_manager.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../base.dart';

class CpdsRoutes extends BaseRouteGroup {
  @override
  String get prefix => '';

  @override
  Router register(Router router) {
    router.get('/state', CpdsController.getState);
    router.post('/package/upload', CpdsController.upload);
    router.post('/package/parse', CpdsController.parse);
    router.post('/nodes/select', CpdsController.selectNode);
    router.post('/nodes/select-future-warrior', CpdsController.selectFutureWarrior);
    router.get('/network-interfaces', CpdsController.listNetworkInterfaces);
    router.post(
      '/network-interfaces/select',
      CpdsController.selectNetworkInterface,
    );
    router.post('/distributions', CpdsController.startDistribution);
    router.post(
      '/distributions/decision',
      CpdsController.resolveDiscoveryMismatch,
    );
    router.get(
      '/events',
      webSocketHandler(
        (WebSocketChannel webSocket, String? protocol) {
          final manager = CpdsManager.instance;
          webSocket.sink.add(jsonEncode(manager.state().toJson()));
          final subscription = manager.stateStream.listen((state) {
            if (webSocket.closeCode != null) return;
            webSocket.sink.add(jsonEncode(state.toJson()));
          });
          webSocket.stream.listen(
            (_) {},
            onDone: () => subscription.cancel(),
            onError: (_) => subscription.cancel(),
            cancelOnError: true,
          );
        },
        pingInterval: const Duration(seconds: 20),
      ),
    );
    return router;
  }
}
