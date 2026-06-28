import 'package:flutter_kts_template/core/utils/director.dart';

import '../../logger/logger.dart';
import '../../objectbox.g.dart';

class DatabaseManager {
  static DatabaseManager? _instance;
  late final Store _store;
  final Map<Type, Box> _boxCache = {};
  Admin? _admin;

  DatabaseManager._create(Store store) : _store = store;

  /// 初始化数据库，可指定数据库名称和路径
  static Future<DatabaseManager> init() async {
    if (_instance != null) return _instance!;
    String dbPath = await DirectoryManager.instance.getDataBasePath();
    final store = await openStore(
      directory: dbPath,
      debugFlags: DebugFlags.logQueries | DebugFlags.logQueryParameters,
    );
    _instance = DatabaseManager._create(store);
    // OS 访问: http://localhost:8081
    // Android 访问:http://10.0.2.2:8081
    GlobalLogger.logInfo("DBServer start $dbPath");
    return _instance!;
  }

  /// 获取已初始化的实例（确保已调用 init）
  static DatabaseManager get instance {
    final inst = _instance;
    if (inst == null) throw StateError('DatabaseManager 尚未初始化，请先调用 init()');
    return inst;
  }

  /// 根据类型获取缓存 Box
  Box<T> box<T>() {
    return _boxCache.putIfAbsent(T, () => _store.box<T>()) as Box<T>;
  }

  /// 关闭 Admin 服务（如需在应用运行期间单独关闭）
  void closeAdmin() {
    if (_admin != null) {
      _admin = null;
    }
  }

  // ----------------------------- CURD ------------------------------------
  int put<T>(T entity) => box<T>().put(entity);
  List<int> putMany<T>(List<T> entities) => box<T>().putMany(entities);
  T? get<T>(int id) => box<T>().get(id);
  List<T> getAll<T>() => box<T>().getAll();
  bool remove<T>(int id) => box<T>().remove(id);
  int removeAll<T>() => box<T>().removeAll();
  int count<T>() => box<T>().count();

  // 事务
  Future<T> writeTransaction<T>(T Function(Store store) action) async {
    return _store.runInTransaction(TxMode.write, () => action(_store));
  }

  // 后台事务
  Future<T> writeTransactionAsync<T, P>(
    T Function(Store store, P param) action,
    P param,
  ) {
    return _store.runInTransactionAsync<T, P>(
      TxMode.write,
      (store, p) => action(store, p),
      param,
    );
  }

  bool get isClosed => _store.isClosed();

  void close() {
    closeAdmin();
    _store.close();
    _boxCache.clear();
    _instance = null;
  }
}
