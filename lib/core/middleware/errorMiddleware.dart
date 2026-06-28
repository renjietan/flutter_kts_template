import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:shelf/shelf.dart';

import '../../logger/logger.dart';
import '../utils/response.dart';

Middleware errorHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (error, stackTrace) {
        GlobalLogger.logError("errors: $error\n stackTrace: $stackTrace");
        if (error is ArgumentError) {
          return ApiResponse.error(
            message: t.errorMiddle.errorArg(error: error.message),
          );
        }
        return ApiResponse.internalError(message: t.errorMiddle.error500);
      }
    };
  };
}
