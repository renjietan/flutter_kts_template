按 `planning-and-task-breakdown` 的思路来拆。先说明两个环境限制，避免我给出无法落地的任务：

1. 我没能读到该技能的 `SKILL.md`，`exec_command` 和 `apply_patch` 都持续报运行时错误（`helper_unknown_error`）；所以我按其核心原则（薄切片、可独立验证、明确依赖顺序）来拆。
2. 同样因为 shell 不可用，我现在**无法扫描代码**定位 `注钥枪列表` 保存路径、ObjectBox 模型、路由/菜单、UDP 封装这些接入点。因此下面把「前置调研」列为 Task 0，是**开工前的硬阻断项**。

下面是拆好的实现任务清单（CPDS=本项目 Flutter；CPDC=设备端 Go，独立仓库）。

---

## Phase 0 — 前置调研（先做，产出接入点清单）

**T0 摸清 6 个接入点**
- 目标：定位并记录：
    1. `注钥枪列表` 的保存路径（用于确定 `install` 文件夹同级目录）；
    2. ObjectBox 实体定义/注册方式与现有分页/搜索模式；
    3. 页面、路由（go_router）、左侧菜单的注册写法；
    4. UDP 收发封装（现有 `udp` 用法、端口、绑定/广播方式）；
    5. `uploads`、`zipCache` 目录常量定义位置；
    6. `archive`（ZIP）、`crypto`（CRC32）依赖是否已引入。
- 验证：产出一份「接入点 → 文件:行号」清单 + 目录/命名约定，供后续任务引用。
- 依赖：无。

---

## Phase 1 — 数据与存储层（CPDS）

**T1 InstallPackage 实体 + 入库/覆盖**
- 目标：新增 ObjectBox 实体（version、fileName、remark、createdAt），实现「相同 version 覆盖」。
- 验证：`fvm flutter test`（新增单测：插入、覆盖、查询、创建时间降序）。
- 依赖：T0。

**T2 存储服务**
- 目标：封装 `install` 目录定位、ZIP 保存、解压 + 同名文件夹逻辑（多目录→新建 `install_yyyyMMdd_HHmmss`；单目录→重命名）、删除 ZIP+同名文件夹。
- 验证：单测（用临时目录 mock 文件系统，覆盖多目录/单目录/删除三态）。
- 依赖：T0。

---

## Phase 2 — 上传页面（CPDS）

**T3 上传页面 + 表格**
- 目标：表格（版本号/文件名称/备注/创建时间）+ 右上角【文件上传】按钮 + 分页/搜索 + 创建时间降序 + 每行「删除/更新到设备」两个操作。
- 验证：`fvm flutter analyze` + 组件测试（渲染、排序、空态）。
- 依赖：T1。

**T4 上传弹窗**
- 目标：三区域 —— version（必填、仅数字、`0.1.1.1` 四段校验）、备注（textarea、≤150 字、选填）、文件上传（只读框 + 【上传】按钮 + 上传中进度条、成功消失）。
- 验证：组件测试（version 校验规则、备注长度限制、进度条显示/隐藏）。
- 依赖：T3。

**T5 上传主流程 + 删除**
- 目标：串联「选 ZIP→存 install 目录→解压/命名→弹窗填 version/备注→入库（覆盖）」；删除行 = 删记录 + 删 ZIP + 删同名文件夹。
- 验证：单测 + 组件测试（上传成功入库、同 version 覆盖、删除清理文件）。
- 依赖：T2、T4。

**T6 左侧菜单入口**
- 目标：在左侧菜单新增「自更新」入口并注册路由。
- 验证：`fvm flutter analyze` + 路由/菜单组件测试。
- 依赖：T3。

---

## Phase 3 — UDP 协议层（CPDS，纯逻辑 + mock，可先行）

**T7 协议 codec**
- 目标：实现独立协议编解码：`Scan`/`Scan:success`、`auth`/`authAck:#`、`version`/`versionAck:#`、`file:`/`fileAck:`（含 uint32BE + CRC32(4B)）、`packet:`/`packetAck:`、`valid_ok`/`valid_fail`、`update_ok`/`update_fail`。
- 验证：单测（字节级编解码往返、大端序、`#` 分隔、CRC32 计算）。
- 依赖：T0。

**T8 广播会话状态机**
- 目标：封装「发指令→启动超时器→等回复清除→发下一条」，5s（认证/版本校验）/3s（传输/校验）超时、连续 3 次超时终止、统一复位（关 UDP + 清变量/缓存/状态）。
- 验证：单测（mock UDP：正常回复、超时重发、3 次终止、复位）。
- 依赖：T7。

---
## Phase 4 — 更新流程 UI（CPDS）

**T9 扫描倒计时进度框**
- 目标：10 秒倒计时圆形进度框，三行文字「扫描中.... / 已扫描到 N 个设备 / 剩余秒」+【取消】；取消/到时无设备 → 复位+关 UDP+提示。
- 验证：组件测试（倒计时、设备数刷新、取消复位、空设备提示）。
- 依赖：T8。

**T10 步骤弹窗（骨架）**
- 目标：7 步横向步骤条（待执行/进行中/成功/失败图标）+ 设备明细表 7 列（IP 地址/类型/当前版本/新版本/状态/进度/结果）+ 按钮状态机（开始/暂停/取消/关闭）。
- 验证：组件测试（步骤状态切换、表格列、按钮 enable/disable）。
- 依赖：T9。

**T11 认证 + 版本校验流程**
- 目标：弹窗打开立即 `auth`（5s/3 次超时、loading、IP 重复标记 `IP（重复）`）→ 成功后立即 `version`（三点 loading、按 类型#IP 匹配填当前版本、读上传目录 cpdc_config.json 填新版本）→ 暂停等待用户。
- 验证：单测 + 组件测试（mock UDP 回复、匹配/重复、超时终止）。
- 依赖：T10、T8。

**T12 传输 + 校验流程**
- 目标：勾选行→按设备类型打包 ZIP→1400 字节分包→`file:` 前置 + `packet:` 分包（3s/3 次超时）→ 收 `packetAck` → 等 `valid_ok`/`valid_fail`（5S）。
- 验证：单测（mock UDP：分包顺序、CRC32、超时重发、valid 结果）。
- 依赖：T11。

**T13 写入 + 回执流程**
- 目标：`valid_ok` 后进入写入→回执 30 秒窗口监听 `update_ok`/`update_fail`，按 类型#IP 标记结果；全流程任意取消/失败/意外终止/完成统一复位。
- 验证：单测 + 组件测试（回执窗口、超时标记、复位）。
- 依赖：T12。

---

## Phase 5 — CPDC 端（Go，独立仓库 CPDC-main）

**T14 读取 version 字段**
- 目标：cpdc_config.json 根节点 `version` 读取，供 `versionAck`/回执使用。
- 验证：Go 单测。
- 依赖：无（独立仓库）。

**T15 新协议响应 + 收包校验**
- 目标：响应 `Scan`/`auth`/`version`；接收 `file:`/`packet:`，按包号组装 ZIP，校验字节数 + CRC32 + 可解压，回 `fileAck`/`packetAck`/`valid_ok`/`valid_fail`。
- 验证：Go 单测（mock 收包/组装/CRC32）。
- 依赖：T14。

**T16 写入安装逻辑**
- 目标：解压→按设备类型匹配文件→覆盖 JSON（`--config-path`）/安装文件/INI（仅当 ini 存在且按 `ReReadjsonPath`）→持久化「待回执」标记→强杀并重启。
- 验证：Go 单测（mock 文件系统 + 运行命令解析）。
- 依赖：T15。

**T17 重启后回执**
- 目标：重启后检测「待回执」→广播 `update_ok`/`update_fail`→成功后清标记。
- 验证：Go 单测（mock 标记文件 + 回执发送）。
- 依赖：T16。

---

## Phase 6 — 集成与验证

**T18 端到端联调**
- 目标：CPDS↔CPDC 全流程联调（mock UDP，或真实双机）。
- 验证：端到端场景（发现→认证→版本校验→传输→校验→写入→回执，含超时/取消/失败分支）。
- 依赖：T13、T17。

**T19 全量验证门禁**
- 目标：`fvm flutter analyze` + `fvm flutter test` + `fvm dart format --output=none --set-exit-if-changed lib test`（+ 按需 `fvm flutter build apk --release --split-per-abi`）；Go 侧 `go test ./...`。
- 验证：全部通过。
- 依赖：T18。

---

**关键依赖链**：`T0 → T1/T2 → T3/T4/T5 → T6`，`T0 → T7 → T8 → T9 → T10 → T11 → T12 → T13`，`T14 → T15 → T16 → T17`，两条线在 `T18` 汇合。

**当前阻塞**：`T0` 需要读代码，但现在的 shell/文件通道坏了，我暂时无法执行 `rg`/`Get-Content`。你可以先重启/恢复 Codex 环境（或告诉我改用别的方式），我再从 `T0` 开始落地；也可以先人工把 `注钥枪列表` 路径、ObjectBox 模型文件、UDP 封装文件这几个位置指给我，我直接据此推进后续任务。你想怎么走？