# AGENTS.md — flutter_kts_template

## 项目概览
Flutter 多平台应用（Android / iOS / Windows 等），业务聚焦 CPD/CPDS。
- Flutter 版本固定为 3.38.10（见 `.fvmrc`），使用 FVM 调用。
- Android 包名 `com.hytera.cpd`。
- 仓库位于 `master` 分支，工作区常有不相关未提交改动。

## 澄清优先（硬规则）
接到新功能点 / 改动需求后，先判断是否有不清楚的地方：验收标准、边界条件、数据来源、UI / 交互细节、兼容范围、错误处理等。只要有任何不确定，先列出具体问题向用户确认，**得到明确答复后才开始修改代码**；禁止凭假设直接实现。

## 功能迭代开发默认链路
对任何非琐碎改动，按以下顺序执行，并路由到对应技能：123

1. 需求/规格澄清 — 需求不清时用 `spec-driven-development`、`interview-me`、`idea-refine`。
2. 任务拆分 — 用 `planning-and-task-breakdown` 拆成可独立验证的薄切片。
3. 增量实现 — 用 `incremental-implementation`，一次只落地一个薄切片，禁止一次性大改。
4. 测试先行 — 用 `test-driven-development`（或 `tdd-workflow`），先写失败测试再实现。
5. 验证 — 用 `verification-loop`，跑下方「验证命令」，全部通过才进入下一片。
6. 审查 — 用 `code-review-and-quality` 自查后再提交。

默认最小技能组合：`spec-driven-development` → `incremental-implementation` → `test-driven-development` → `verification-loop`。

## 验证命令（全部通过才算完成）
- 静态分析：`fvm flutter analyze`
- 单元/组件测试：`fvm flutter test`
- 格式校验：`fvm dart format --output=none --set-exit-if-changed lib test`
- 构建（按需）：`fvm flutter build apk --release --split-per-abi`

> `fvm` 已安装。若环境无 fvm，可去掉 `fvm ` 前缀用全局 Flutter，但版本必须保持 3.38.10。

## MCP 使用
- `context7`：查 Flutter/Dart 及第三方依赖的最新官方文档，避免用过时 API。
- `playwright`：对 Web 构建做浏览器级回归时使用。
- `github`：PR / issue / 代码浏览（已在全局配置）。

## 约定
- 外科手术式修改：只改动任务相关文件，不顺手重构或格式化无关代码。
- 保持 `lib/` 现有分层与命名风格。
- 涉及 USB / 串口等硬件逻辑时，测试必须 mock 硬件依赖，不得依赖真实设备。