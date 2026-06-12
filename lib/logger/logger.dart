import 'package:logger/logger.dart';

class GlobalLogger {

  static Logger L = Logger(printer: HybridPrinter(PrefixPrinter(
    SimplePrinter(
      printTime: true
    ),
    trace: '[跟踪]',
    info: '[信息]',
    warning: '[警告]',
    // debug: '[调试]',
    // error: '[错误]',
    // fatal: '[灾难]'
  ), debug: PrettyPrinter(), error: PrettyPrinter(), fatal: PrettyPrinter()));

  static void logTrace(String msg) {
    L.v(msg, time: DateTime.now());
  }

  static void logDebug(String msg) {
    L.d(msg, time: DateTime.now());
  }
  static void logInfo(String msg) {
    L.i(msg,time: DateTime.now());
  }
  static void logWarn(String msg) {
    L.w(msg, time: DateTime.now());
  }
  static void logError(String msg) {
    L.e(msg, time: DateTime.now());
  }
  static void logWTF(String msg) {
    L.wtf(msg,time: DateTime.now());
  }
}

// const String _tag = "easy_tab_controller";
// // Logger _logger = Logger(printer: HybridPrinter(PrefixPrinter(
// //   SimplePrinter(),
// //   trace: '[跟踪]',
// //   debug: '[调试]',
// //   info: '[信息]',
// //   warning: '[警告]',
// //   // error: '[错误]',
// //   // fatal: '[灾难]'
// // ), error: PrettyPrinter(), fatal: PrettyPrinter()));
// // Logger(printer: LogfmtPrinter());
// Logger _logger = Logger(printer: LogfmtPrinter());
//
//
//
// void LogTrace(String msg) {
//   _logger.v("$msg");
// }
//
// void LogD(String msg) {
//   _logger.d("$msg");
// }
//
// void LogI(String msg) {
//   _logger.i("$msg");
// }
//
// void LogW(String msg) {
//   _logger.w("$msg");
// }
//
// void LogE(String msg) {
//   _logger.e("$msg");
// }
//
// void LogWTF(String msg) {
//   _logger.wtf("$msg");
// }