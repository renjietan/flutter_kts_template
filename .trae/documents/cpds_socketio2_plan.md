# CPDS (SocketIO2) Flutter Android 实现计划

## 一、需求概要

根据 `xq/` 目录下三份需求文档，实现 CPDS（Communication Plan Distribution Server）端在 Flutter Android 上的通信保障配置包下发功能。

### 核心协议特征
- **协议**: Proto3 二进制协议 + 4 字节 Magic 前缀 (`0xEEDDCCBB`)
- **CPDS 接收端口**: UDP 39002
- **CPDC 接收端口**: UDP 39001
- **广播地址**: `255.255.255.255` + 环回 `127.0.0.1`
- **最大 UDP 负载**: 1400 字节（4 字节 Magic + 1396 字节 Proto3 Packet）
- **分包负载**: 固定 1200 字节
- **传输速率**: 1 Mbit/s 名义负载速率

### CPDS 状态机
```
Ready → Discovering → (AwaitingDiscoveryConfirmation) → Authenticating → Transferring → Parsing → Completed/PartialSuccess/Failed
```

### 12 种协议消息
| 消息 | 方向 | 说明 |
|------|------|------|
| DISCOVER_NTY | CPDS→CPDC | 发现通知（空消息体） |
| DISCOVER_RSP | CPDC→CPDS | 发现回复（ESN, device_types, IP, mask, instance_nonce） |
| AUTH_NTY | CPDS→CPDC | 认证通知（assignments: device_type, esn, node_id, device_id） |
| AUTH_RSP | CPDC→CPDS | 认证回复（SUCCESS/FAILED + bindings） |
| TRANSFER_START_NTY | CPDS→CPDC | 传输开始通知（file_name, file_size, sha256, chunk_size, total_chunks...） |
| TRANSFER_CHUNK_NTY | CPDS→CPDC | 数据分包（chunk_index, payload, payload_crc32） |
| TRANSFER_PROGRESS_RSP | CPDC→CPDS | 传输进度回复 |
| TRANSFER_END_NTY | CPDS→CPDC | 传输结束通知（空消息体） |
| TRANSFER_LOSSPACK_REQ | CPDC→CPDS | 缺包请求（missing_ranges: start, end） |
| TRANSFER_COMPLETE_RSP | CPDC→CPDS | 传输完成回复 |
| PARSE_COMPLETE_REQ | CPDC→CPDS | 解析完成请求（result, type_results） |
| PARSE_COMPLETE_ACK | CPDS→CPDC | 解析完成确认 |

---

## 二、文件结构规划

```
lib/core/rtc/managers/socketIO2/
├── cpd_enums.dart              # 枚举定义（设备类型、错误码、阶段、Result 等）
├── cpd_config.dart             # 时间常量与协议配置
├── cpd_models.dart             # 数据模型（DeviceBinding, Session, DiscoverResult 等）
├── cpd_protocol.dart           # Proto3 编解码 + Magic 封装/拆包
├── cpd_state_machine.dart      # CPDS 状态机核心逻辑
└── socket_io2_manager.dart     # 主管理器（实现 RtcAbstract，对外接口）
```

---

## 三、各文件职责

### 1. `cpd_enums.dart` — 枚举定义
- `DeviceType` 枚举: UNKNOWN=0, SERVER=1, IEC=2, CCU=3, CCU_AUDIO=8, MULTIBAND_RADIO=4, MULTIBAND_HANDHELD=5, HF=6, SMALL_HANDHELD=7
- `Result` 枚举: UNSPECIFIED=0, SUCCESS=1, FAILED=2
- `ParseStage` 枚举: UNSPECIFIED=0, PRECHECK=1, RECEIVE=2, VERIFY=3, CACHE_REUSE=4, SKIPPED=5
- `TransferStage` 枚举: UNSPECIFIED=0, PRECHECK=1, RECEIVE=2, VERIFY=3, CACHE_REUSE=4
- `ErrorCode` 枚举: 全部错误码（INVALID_MESSAGE, INVALID_PACKAGE, PACKAGE_TOO_LARGE, AUTH_CONFLICT 等）
- `CpdActiveState` 枚举: CPDS 前端状态（IDLE, DISCOVERING, AUTHENTICATING, TRANSFERRING 等）

### 2. `cpd_config.dart` — 常量配置
```dart
class CpdConfig {
  static const int magic = 0xEEDDCCBB;
  static const int cpdcPort = 39001;
  static const int cpdsPort = 39002;
  static const int maxUdpPayload = 1400;
  static const int maxPacketSize = 1396;
  static const int chunkPayloadSize = 1200;
  static const int maxFileSize = 1048576; // 1 MiB
  static const int transferPayloadRateBps = 1000000; // 1 Mbit/s
  
  // 时间常量
  static const Duration discoverWindow = Duration(seconds: 5);
  static const Duration discoverInterval = Duration(seconds: 1);
  static const Duration authWindow = Duration(seconds: 5);
  static const Duration authRetryInterval = Duration(seconds: 1);
  static const Duration transferStartRefreshInterval = Duration(seconds: 1);
  static const Duration transferWaitRetryInterval = Duration(seconds: 1);
  static const Duration transferSilenceTimeout = Duration(seconds: 10);
  static const Duration transferNoProgressTimeout = Duration(seconds: 30);
  static const Duration parseResultWaitTimeout = Duration(seconds: 35);
}
```

### 3. `cpd_models.dart` — 数据模型
- `Packet` 模型: sessionId (Uint8List[16]), messageId (Uint8List[16]), body (oneof)
- `ClientIdentity`: esn (String), deviceTypes (List<String>)
- `AuthAssignment`: deviceType, esn, nodeId, deviceId
- `AuthBinding`: deviceType, nodeId, deviceId
- `DiscoverResult`: esn, instanceNonce, deviceTypes, currentIp, subnetMask
- `DeviceStatus`: 追踪每个 CPDC 设备的实时状态
- `CpdSession`: 整个下发会话状态
- `TransferChunkInfo`: 分包信息

### 4. `cpd_protocol.dart` — Proto3 编解码
这是核心层，使用 `protobuf` Dart 包实现：
- **编码**: 构造 `Packet` → 序列化为 Proto3 二进制 → 前置 4 字节 Magic → 返回 `Uint8List`
- **解码**: 接收 `Uint8List` → 校验长度 ≥ 4 → 校验 Magic → 反序列化 Proto3 `Packet` → 返回解析结果
- **消息类型识别**: 通过 `Packet` 的 oneof body 字段号判断消息类型
- **CRC32/IEEE**: 用于分包 `payload_crc32` 校验
- **分片处理**: AUTH_NTY 和 TRANSFER_LOSSPACK_REQ 按 1400 字节限制自动分片

### 5. `cpd_state_machine.dart` — 状态机
实现 CPDS 完整业务流程：
- **发现阶段**: 5 秒窗口，每秒广播 DISCOVER_NTY，收集 DISCOVER_RSP，ESN 冲突检测，数量比较
- **认证阶段**: 自动配对（ESN 升序 × 设备顺序），AUTH_NTY 分片发送，AUTH_RSP 收集
- **传输阶段**: START×2 → CHUNK 发送（1 Mbit/s 节流）→ START×2 + END → 缺包补发 → TRANSFER_COMPLETE_RSP 等待
- **解析等待**: 35 秒超时窗口，PARSE_COMPLETE_REQ 处理，PARSE_COMPLETE_ACK 回复
- **结果结算**: COMPLETED / PARTIAL_SUCCESS / FAILED 判定

### 6. `socket_io2_manager.dart` — 主管理器
- 实现 `RtcAbstract` 接口
- 管理 UDP Socket（绑定端口 39002）
- 广播 + 环回双发
- 提供 `startDistribution()` / `stopDistribution()` 对外 API
- 通过 Stream 输出状态变化供 UI 层消费
- 管理多个 CPDC 设备的独立状态追踪

---

## 四、依赖与改动

### 需要添加的 pubspec.yaml 依赖
```yaml
dependencies:
  protobuf: ^3.2.0    # Proto3 编解码
  uuid: ^4.2.0        # UUID v4 生成 (session_id, message_id)
  crypto: ^3.0.6      # SHA-256 计算
```

### 复用现有依赖
- `udp: ^5.0.3` — UDP Socket 通信
- `network_info_plus: ^7.0.0` — 网络接口枚举
- `archive: ^4.0.9` — ZIP 解析

### 不需要的依赖
- 无需 `socket_io_client`（本项目需求明确使用原生 UDP + Proto3，不是 Socket.IO WebSocket）

---

## 五、实现步骤

### 阶段一：基础设施
1. 添加 `protobuf`、`uuid`、`crypto` 依赖到 pubspec.yaml
2. 创建 `cpd_enums.dart` — 所有枚举定义
3. 创建 `cpd_config.dart` — 时间常量与协议配置
4. 创建 `cpd_models.dart` — 数据模型

### 阶段二：协议层
5. 创建 `cpd_protocol.dart` — Proto3 编解码实现
   - 定义 Packet 消息结构（使用 protobuf 的 Map 编码或手写兼容编码）
   - 实现 Magic 封装/拆包
   - 实现消息类型的序列化与反序列化
   - 实现 CRC32/IEEE 计算

### 阶段三：状态机
6. 创建 `cpd_state_machine.dart` — 完整 CPDS 业务流程
   - 实现发现、认证、传输、解析等待四个阶段的逻辑
   - 实现定时器管理（发现窗口、认证窗口、传输节流、超时等）
   - 实现缺包补发逻辑
   - 实现幂等去重

### 阶段四：管理器
7. 创建 `socket_io2_manager.dart` — 对外接口
   - 实现 RtcAbstract 接口
   - UDP Socket 管理
   - 广播 + 环回双发
   - 状态事件流输出

### 阶段五：验证
8. 运行 `flutter pub get` 确保依赖正确
9. 运行 `flutter analyze` 确保无语法错误
10. 验证与现有代码的接口兼容性

---

## 六、风险与注意事项

1. **Proto3 兼容性**: Dart protobuf 包与 Go protobuf 的线级兼容性需注意字段号、编码方式一致。建议使用标准的 `protobuf` 包实现。

2. **UDP 接收端**: Android 端需处理网络权限，代码中需要声明 `android.permission.INTERNET` 和 `android.permission.ACCESS_NETWORK_STATE`。

3. **后台线程**: Flutter UI 主线程外的 UDP 收发需注意不要阻塞 UI，应使用 Isolate 或 Timer 调度。

4. **多网卡**: Android 可能有多个网络接口（移动数据/WiFi），需要枚举并选择正确的接口。

5. **去重逻辑**: 相同 message_id 的消息（广播+环回副本）必须去重，但 DISCOVER_RSP 还需用 instance_nonce 区分。

6. **文件大小限制**: 通信包最大 1 MiB，所有校验必须在传输前完成。

7. **不修改现有代码**: 仅新增 `socketIO2` 目录，不修改现有 `socketIO`、`udp`、`win-usb` 等目录下的代码。
