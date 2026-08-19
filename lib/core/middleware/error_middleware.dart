import 'dart:convert';

import 'package:flutter_kts_template/core/cpds/cpds_exception.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
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
        if (error is HijackException) {
          rethrow;
        }
        if (error is CpdsException) {
          GlobalLogger.logWarn(
            "Business error: ${error.code.apiName} params=${error.params}",
          );
          return _cpdsError(error);
        }
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

Response _cpdsError(CpdsException error) {
  var statusCode = 400;
  if (error.code == CpdsErrorCode.packageTooLarge) {
    statusCode = 413;
  } else if (error.code == CpdsErrorCode.busy) {
    statusCode = 409;
  } else if (error.code == CpdsErrorCode.storageIoError) {
    statusCode = 500;
  }
  return Response(
    statusCode,
    body: jsonEncode({
      'errorCode': error.code.apiName,
      'params': error.params,
    }),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
