

import 'package:flutter_kts_template/logger/logger.dart';
import 'package:shelf/shelf.dart';

Middleware customLogger() {
  return (Handler innerHandler) {
    return (Request request) async {
      final start = DateTime.now();
      final response = await innerHandler(request);
      final duration = DateTime.now().difference(start);

      if(response.statusCode != 200) {
        try {
          GlobalLogger.logError(
              "url: ${request.url}\n"
              "request: ${request.method}\n"
              "statusCode: ${response.statusCode}\n"
              "inMilliseconds: ${duration.inMilliseconds}\n"
          );
        } catch (err) {
          GlobalLogger.logError(err.toString());
        }

      } else {
        GlobalLogger.logDebug(
            "url: ${request.url}\n"
            "request: ${request.method}\n"
            "statusCode: ${response.statusCode}\n"
            "inMilliseconds: ${duration.inMilliseconds}\n"
            "data: ${ request.context["params"] }"
        );
      }
      return response;
    };
  };
}