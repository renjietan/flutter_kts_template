import 'package:flutter_kts_template/core/utils/response.dart';
import 'package:shelf/shelf.dart';

import '../../logger/logger.dart';

Middleware errorHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (error, stackTrace) {
        GlobalLogger.logError("errors: $error\n stackTrace: $stackTrace");
        if (error is ArgumentError) {
          return ApiResponse.error(message: 'Invalid argument: ${error.message}');
        }
        // 默认返回 500 Internal Server Error
        return ApiResponse.internalError(
          message: 'An unexpected error occurred. Please try again later.',
        );
      }
    };
  };
}