# CPDS 技术方案

## 1. 目标与边界

CPDS 使用一套 Go 核心业务代码和一套 Vue 3 页面，发布为 Windows Wails 桌面程序与 Linux/amd64 CCU Web 服务。本项目只实现 CPDS；不引用、生成或修改 CPDC 工程中的任何源码或资源。

实现遵循现有三份需求说明及 `proto/cpd.proto`。首期只实现“参数加注”，不为未启用菜单建立占位业务模块。

## 2. 技术选型

| 层 | 方案 | 说明 |
|---|---|---|
| 后端 | Go 1.25，标准库为主 | ZIP、JSON、UDP、SHA-256、CRC32、HTTP 均使用标准库 |
| UDP 格式 | Proto3 + 4 字节 Magic | 从本项目 `proto/cpd.proto`生成 Go 类型；不使用 gRPC |
| 实时通道 | `gorilla/websocket` | CCU 浏览器的实时状态通道；HTTP 与 WebSocket 共用 18080 |
| 桌面外壳 | Wails v2 | Windows 原生窗口、窗口控制及 Vue 页面承载 |
| 前端 | Vue 3 + Vite | Composition API，不引入全局状态框架 |
| 国际化 | vue-i18n | `zh-CN`、`en-US`、`ar-SA`，英文回退，RTL 完整适配 |
| 测试 | Go `testing` + Vitest/Test Utils | 所有测试源码集中在 `tests/` |

## 3. 代码结构

```text
CPDS/
├─ cmd/
│  ├─ cpds-ccu/          # Linux Web 服务入口
│  └─ cpds-desktop/      # Windows Wails 入口
├─ gen/cpd/v1/           # 本项目 Proto 生成代码
├─ internal/
│  ├─ api/               # HTTP、WebSocket、桌面共用门面
│  ├─ model/             # 前后端稳定 DTO 与业务模型
│  ├─ packageio/         # 上传、ZIP 安全校验、JSON 解析、节点索引
│  ├─ protocol/          # Magic 封装、UDP 双发、速率及时间参数
│  ├─ session/           # Distribution 状态机和设备状态
│  └─ platform/          # Wails/Web 宿主能力边界
├─ frontend/src/
│  ├─ components/        # Figma 区域组件
│  ├─ composables/       # 轻量页面状态与语言状态
│  ├─ i18n/ locales/     # 国际化初始化与三套同构资源
│  ├─ services/          # Wails/HTTP 适配
│  └─ styles/            # Token、逻辑属性和 RTL 样式
├─ tests/                # 全部 Go 和前端测试源码
├─ proto/cpd.proto
└─ docs/
```

目录按真实职责拆分，避免按每个结构体或每个接口过度切文件。核心层不依赖 Wails、HTTP 或 Vue，两个发布宿主只负责启动与桥接。

## 4. 后端流程

### 4.1 导入与解析

上传流先写入随机临时文件并执行 1 MiB 上限、SHA-256 与磁盘空间检查。解析器一次遍历 ZIP 中央目录建立大小和路径清单，再逐个流式读取 JSON 并校验 CRC。合法内容被转换为不可变 `PackageSnapshot`：原始文件元数据、单位树、节点索引、设备配置索引、解压大小及工作空间估算。

解析器只接受业务目录直接位于 ZIP 根的正式格式和 `1_resource`。输入中的 `local_node.json`仅接受通用 ZIP 安全检查，不参与业务解析。

### 4.2 Distribution

`Manager`同一时刻只持有一个活动会话。开始下发时复制包和节点数据，随后驱动：

```text
DISCOVERING → AUTHENTICATING → TRANSFERRING → WAITING_PARSE → COMPLETED
                                                      └──────→ FAILED
```

发现和认证失败立即结束；传输或解析出现单设备失败后进入 `DRAINING_AFTER_FAILURE`语义，继续处理其他非终态实例，最后统一失败。设备终态不可被迟到报文改写，重复最终请求仍会得到 ACK。

会话事件通过单一订阅接口同时提供给 WebSocket 和 Wails，避免维护两套业务状态。

### 4.3 UDP

网络层只发送本地状态机创建的报文。每次逻辑发送生成一次二进制数据，最多写向 `255.255.255.255:39001`与 `127.0.0.1:39001`各一次；收到的报文绝不转发，因此不会产生反射环路或广播风暴。

发送与接收套接字绑定用户指定或自动选中的有线 IPv4 接口。Magic 在反序列化前校验。每个 UDP 负载上限 1400 字节，数据负载 1200 字节；文件分包采用 1 Mbit/s 名义负载速率。全部时间参数集中在 CPDS 自己的 `internal/protocol/timing.go`。

## 5. 前端设计

页面以 Figma `3765:3953`的 1366×768 布局为视觉基准：40 px TopBar、112 px 菜单、717 px 左功能区和 536 px 右状态区。颜色、行高、间距、边框与图标使用 Figma token 和导出资源。

右侧保留原始紧凑分组结构，替换逐设备 Inject：顶部显示当前节点、在线数和下发按钮；其下显示五阶段状态条；设备行显示类型、ID、ESN 后 6 位、IP 和状态。只有 Transfer 阶段渲染服务端发送进度和设备接收进度。

页面在小于基准宽度时保留可用性，但桌面/CCU主视图优先严格复现基准布局。阿拉伯语通过 `dir=rtl`与 CSS 逻辑属性镜像侧栏、双栏、箭头、操作顺序和弹窗；数值进度仍保持 0→100 的视觉方向。

## 6. 错误与日志

后端只向前端返回 `ErrorCode + params`，不拼装自然语言。Vue 根据当前语言实时翻译，包括已经打开的失败弹窗。日志在序列化前递归脱敏 password、passwd、secret、privateKey 和密钥内容，不记录 UDP 文件负载或完整 JSON。

## 7. 测试策略

测试遵循先失败后实现：

1. ZIP 安全、目录、引用、类型映射和样例节点解析。
2. Magic/Proto 报文上限、UUID、分包与认证拆包。
3. 发现、认证、传输失败排空、解析等待、终态幂等状态机。
4. HTTP/WebSocket DTO 与活动会话互斥。
5. 三语键一致、回退、切换持久化、`lang/dir`与 RTL。
6. Figma 基准布局、Transfer 独占进度条和弹窗动态翻译。

测试不依赖 `D:\CPD\Res`，所需 ZIP 均在测试中确定性生成，使 CPDS 工程可以独立构建和验收。
