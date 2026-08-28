# Discovery Mismatch Confirmation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (\`- [ ]\`) syntax for tracking.

**Goal:** 在发现设备数量与需求数量不一致时暂停下发并由用户决定是否继续；继续时只向已匹配的在线设备下发，取消时任务失败；所有终态均弹窗展示，并正确区分失败、部分成功和全部成功。

**Architecture:** 会话状态机负责数量不匹配检测、匹配结果和最终状态判定；Runner 通过一次性决策通道等待用户选择；Manager/API/Wails 绑定提供决策入口；Vue 根据会话状态展示确认弹窗和统一结果弹窗。沿用 \`SessionView.devices\` 与 \`SessionView.failures\` 表达缺失和忽略设备，不增加独立不匹配 DTO。

**Tech Stack:** Go 1.25、Wails v2、Vue 3、Vite、Vitest、Go testing

**Status:** Implemented and verified on 2026-07-22.

---

## File Map

- Modify: \`internal/model/model.go\` — 增加等待确认与部分成功状态。
- Modify: \`internal/session/machine.go\` — 发现结果配对、用户决策、终态聚合。
- Modify: \`internal/session/runner.go\` — 等待发现阶段决策并继续流程。
- Modify: \`internal/service/manager.go\` — 保存并投递当前任务的用户决策。
- Modify: \`internal/api/handler.go\` — 增加浏览器模式决策接口。
- Modify: \`cmd/cpds-desktop/app_windows.go\` — 增加桌面模式决策绑定。
- Modify: \`frontend/src/services/cpds.js\` — 封装浏览器/Wails 决策调用。
- Modify: \`frontend/src/App.vue\` — 驱动确认弹窗和全部终态弹窗。
- Modify: \`frontend/src/components/Dashboard.vue\` — 接入确认弹窗与统一结果弹窗。
- Create: \`frontend/src/components/DiscoveryMismatchDialog.vue\` — 展示数量差异并收集继续/取消选择。
- Modify: \`frontend/src/components/FailureDialog.vue\` — 扩展为失败、部分成功、全部成功结果弹窗。
- Modify: \`frontend/src/components/DevicePanel.vue\` — 映射新增状态到正确阶段。
- Modify: \`frontend/src/components/StatusBadge.vue\` — 支持被忽略设备状态。
- Modify: \`frontend/src/locales/{zh-CN,en-US,ar-SA}.js\` — 增加确认及结果文案。
- Modify: \`frontend/src/styles/app.css\` — 增加确认/成功/部分成功弹窗样式。
- Modify: \`tests/session_test.go\`、\`tests/runner_test.go\`、\`tests/api_test.go\` — 覆盖状态机、Runner 与 HTTP 决策入口。
- Modify: \`tests/app_failure.test.js\`、\`tests/dashboard.test.js\` — 覆盖确认交互和全部终态弹窗。

### Task 1: 用测试定义状态机规则

**Files:**
- Modify: \`tests/session_test.go\`
- Modify: \`internal/model/model.go\`
- Modify: \`internal/session/machine.go\`

- [ ] **Step 1: 编写发现数量不匹配的失败测试**

新增测试，覆盖：

\`\`\`go
func TestDiscoveryMismatchWaitsForConfirmation(t *testing.T) {
    // 期望两个设备，只发现一个可匹配设备。
    // FinishDiscovery 后应为 AWAITING_DISCOVERY_CONFIRMATION，且不得开始认证。
}

func TestDiscoveryMismatchContinuePairsOnlyCommonDevices(t *testing.T) {
    // ResolveDiscoveryMismatch(true) 后进入 AUTHENTICATING；
    // 只保留按设备类型、ESN 升序与包内顺序配对的公共区间。
}

func TestDiscoveryMismatchCancelFails(t *testing.T) {
    // ResolveDiscoveryMismatch(false) 后直接 FAILED。
}

func TestDiscoveryMismatchWithNoMatchedDeviceFailsDirectly(t *testing.T) {
    // 零匹配时不等待确认，直接 FAILED。
}
\`\`\`

并把“有成功也有缺失/失败”的旧断言调整为 \`PARTIAL_SUCCESS\`。

- [ ] **Step 2: 运行状态机测试，确认因缺少新状态/方法而失败**

Run:

\`\`\`powershell
go test ./tests -run "DiscoveryMismatch|Mixed|PerType" -count=1
\`\`\`

Expected: 编译失败或断言失败，指出 \`AWAITING_DISCOVERY_CONFIRMATION\`、\`PARTIAL_SUCCESS\` 或决策方法尚不存在。

- [ ] **Step 3: 增加状态常量和最小状态机实现**

在 \`internal/model/model.go\` 增加：

\`\`\`go
const (
    StateAwaitingDiscoveryConfirmation SessionState = "AWAITING_DISCOVERY_CONFIRMATION"
    StatePartialSuccess                 SessionState = "PARTIAL_SUCCESS"
)
\`\`\`

在 \`Machine.FinishDiscovery\` 中按设备类型完成稳定排序及公共区间配对；数量不一致时记录 \`DISCOVERY_MISMATCH\`，有匹配项则进入等待确认，零匹配则失败。增加：

\`\`\`go
func (m *Machine) ResolveDiscoveryMismatch(proceed bool) error
\`\`\`

\`proceed=true\` 进入认证，\`false\` 进入失败；非等待确认状态调用返回错误。缺失目标保留为未成功状态，额外发现设备标记为 \`IGNORED\` 且不加入认证/传输客户端集合。

修改 \`recalculateState\`：发现数量不匹配只影响最终结果，不触发运行中的失败排空；全部逻辑目标结束后，成功数为零是 \`FAILED\`，存在缺失、忽略或设备失败且成功数大于零是 \`PARTIAL_SUCCESS\`，精确匹配且全部成功是 \`COMPLETED\`。

- [ ] **Step 4: 运行状态机测试直至通过**

Run:

\`\`\`powershell
go test ./tests -run "DiscoveryMismatch|Mixed|PerType" -count=1
\`\`\`

Expected: PASS。

- [ ] **Step 5: 检查并提交本任务差异**

Run:

\`\`\`powershell
git diff --check
git status --short --branch
git worktree list
\`\`\`

只暂存本任务文件后提交：

\`\`\`powershell
git add internal/model/model.go internal/session/machine.go tests/session_test.go
git commit -m "feat(discovery-mismatch): add confirmation state machine"
\`\`\`

### Task 2: 贯通 Runner 与 Manager 决策流程

**Files:**
- Modify: \`tests/runner_test.go\`
- Modify: \`internal/session/runner.go\`
- Modify: \`internal/service/manager.go\`

- [ ] **Step 1: 编写 Runner 决策流程失败测试**

增加：

\`\`\`go
func TestRunnerWaitsForDiscoveryDecisionAndContinuesMatchedDevices(t *testing.T) {
    decision := make(chan bool, 1)
    // 数量不匹配后先确认未发送 AUTH，再投递 true；
    // 仅匹配设备完成流程，最终 PARTIAL_SUCCESS。
}

func TestRunnerFailsDirectlyWhenDiscoveryHasNoMatch(t *testing.T) {
    // 不进入等待确认，不发送 AUTH，最终 FAILED。
}
\`\`\`

- [ ] **Step 2: 运行 Runner 测试，确认失败**

Run:

\`\`\`powershell
go test ./tests -run "Runner.*Discovery" -count=1
\`\`\`

Expected: 测试因 Runner 尚无决策通道或仍直接返回数量不匹配错误而失败。

- [ ] **Step 3: 实现决策通道与 Manager 投递**

给 \`RunnerConfig\` 增加：

\`\`\`go
DiscoveryDecision <-chan bool
\`\`\`

发现阶段结束后，若状态为等待确认，则阻塞等待决策、上下文取消或传输错误；收到决策后调用状态机并继续或结束。终态判断同时识别 \`PARTIAL_SUCCESS\`。

给 \`sessionHandle\` 增加容量为 1 的决策通道，并在启动 Runner 时传入。给 Manager 增加：

\`\`\`go
func (m *Manager) ResolveDiscoveryMismatch(sessionID string, proceed bool) error
\`\`\`

只允许当前会话处于等待确认状态时投递，避免重复决策。

- [ ] **Step 4: 运行 Runner 测试直至通过**

Run:

\`\`\`powershell
go test ./tests -run "Runner.*Discovery" -count=1
\`\`\`

Expected: PASS。

- [ ] **Step 5: 检查并提交本任务差异**

Run:

\`\`\`powershell
git diff --check
git status --short --branch
git worktree list
\`\`\`

只暂存本任务文件后提交：

\`\`\`powershell
git add internal/session/runner.go internal/service/manager.go tests/runner_test.go
git commit -m "feat(discovery-mismatch): wait for user decision"
\`\`\`

### Task 3: 暴露 HTTP 与 Wails 决策入口

**Files:**
- Modify: \`tests/api_test.go\`
- Modify: \`internal/api/handler.go\`
- Modify: \`cmd/cpds-desktop/app_windows.go\`
- Modify: \`frontend/src/services/cpds.js\`

- [ ] **Step 1: 编写 HTTP 接口失败测试**

覆盖 \`POST /api/distributions/decision\`：缺少 \`sessionId\`、缺少布尔值 \`proceed\`、无有效等待会话时均返回现有错误协议；合法请求能传递 \`false\` 而不会被当作缺少字段。

- [ ] **Step 2: 运行 API 测试，确认路由不存在**

Run:

\`\`\`powershell
go test ./tests -run "DistributionDecision" -count=1
\`\`\`

Expected: 404 或路由相关断言失败。

- [ ] **Step 3: 实现后端与前端服务入口**

请求体使用指针布尔值区分“取消”与“字段缺失”：

\`\`\`go
type distributionDecisionRequest struct {
    SessionID string \`json:"sessionId"\`
    Proceed   *bool  \`json:"proceed"\`
}
\`\`\`

增加 Wails 方法：

\`\`\`go
func (a *DesktopApp) ResolveDiscoveryMismatch(sessionID string, proceed bool) model.DesktopResult
\`\`\`

前端服务增加：

\`\`\`js
export async function resolveDiscoveryMismatch(sessionId, proceed) {
  // desktop 调用 Wails 绑定；browser POST /api/distributions/decision
}
\`\`\`

- [ ] **Step 4: 运行 API 测试直至通过**

Run:

\`\`\`powershell
go test ./tests -run "DistributionDecision" -count=1
\`\`\`

Expected: PASS。

- [ ] **Step 5: 检查并提交本任务差异**

Run:

\`\`\`powershell
git diff --check
git status --short --branch
git worktree list
\`\`\`

只暂存本任务文件后提交：

\`\`\`powershell
git add internal/api/handler.go cmd/cpds-desktop/app_windows.go frontend/src/services/cpds.js tests/api_test.go
git commit -m "feat(discovery-mismatch): expose decision endpoints"
\`\`\`

### Task 4: 实现发现数量确认弹窗

**Files:**
- Create: \`frontend/src/components/DiscoveryMismatchDialog.vue\`
- Modify: \`frontend/src/App.vue\`
- Modify: \`frontend/src/components/Dashboard.vue\`
- Modify: \`tests/app_failure.test.js\`

- [ ] **Step 1: 编写确认弹窗交互失败测试**

构造 \`activeState: 'AWAITING_DISCOVERY_CONFIRMATION'\` 的会话，断言：

\`\`\`js
expect(wrapper.text()).toContain('设备数量与发现设备数量不匹配')
await wrapper.get('[data-testid="continue-distribution"]').trigger('click')
expect(resolveDiscoveryMismatch).toHaveBeenCalledWith('session-1', true)
\`\`\`

另测取消按钮传 \`false\`，以及普通发现/认证状态不展示弹窗。

- [ ] **Step 2: 运行前端测试，确认组件/交互不存在**

Run:

\`\`\`powershell
npm --prefix frontend test -- app_failure.test.js
\`\`\`

Expected: 测试因确认弹窗和服务调用不存在而失败。

- [ ] **Step 3: 实现不可绕过的确认弹窗**

\`DiscoveryMismatchDialog.vue\` 从 \`session.failures\` 的 \`DISCOVERY_MISMATCH\` 项读取 \`expected\`/\`actual\`，逐类型展示期望、发现、缺失、额外数量；只提供“继续”和“取消”按钮，不提供遮罩关闭或 Escape 关闭。\`Dashboard\` 上抛选择，\`App\` 调用服务后等待后端状态更新，提交期间禁用重复点击。

- [ ] **Step 4: 运行确认交互测试直至通过**

Run:

\`\`\`powershell
npm --prefix frontend test -- app_failure.test.js
\`\`\`

Expected: PASS。

- [ ] **Step 5: 检查并提交本任务差异**

Run:

\`\`\`powershell
git diff --check
git status --short --branch
git worktree list
\`\`\`

只暂存本任务文件后提交：

\`\`\`powershell
git add frontend/src/App.vue frontend/src/components/Dashboard.vue frontend/src/components/DiscoveryMismatchDialog.vue tests/app_failure.test.js
git commit -m "feat(discovery-mismatch): add confirmation dialog"
\`\`\`

### Task 5: 统一失败、部分成功和全部成功结果弹窗

**Files:**
- Modify: \`frontend/src/components/FailureDialog.vue\`
- Modify: \`frontend/src/components/DevicePanel.vue\`
- Modify: \`frontend/src/components/StatusBadge.vue\`
- Modify: \`frontend/src/locales/zh-CN.js\`
- Modify: \`frontend/src/locales/en-US.js\`
- Modify: \`frontend/src/locales/ar-SA.js\`
- Modify: \`frontend/src/styles/app.css\`
- Modify: \`frontend/src/App.vue\`
- Modify: \`frontend/src/components/Dashboard.vue\`
- Modify: \`tests/app_failure.test.js\`
- Modify: \`tests/dashboard.test.js\`

- [ ] **Step 1: 编写三个终态弹窗失败测试**

分别推送 \`FAILED\`、\`PARTIAL_SUCCESS\`、\`COMPLETED\` 会话，断言每个 session 只弹一次；失败弹窗显示失败详情；部分成功和全部成功均显示：

\`\`\`text
请重启通信参数下发成功的相关设备。
\`\`\`

失败弹窗不显示该提示。另断言 \`AWAITING_DISCOVERY_CONFIRMATION\` 映射发现阶段，\`PARTIAL_SUCCESS\` 和 \`COMPLETED\` 映射完成阶段。

- [ ] **Step 2: 运行前端测试，确认新终态尚未支持**

Run:

\`\`\`powershell
npm --prefix frontend test -- app_failure.test.js dashboard.test.js
\`\`\`

Expected: 部分成功/全部成功标题、重启提示或阶段映射断言失败。

- [ ] **Step 3: 实现统一结果展示及多语言文案**

扩展现有 \`FailureDialog.vue\`，根据 \`resultState\` 选择“下发失败”“部分下发成功”“下发成功”，仅成功与部分成功显示重启提示。缺失目标和被忽略设备使用现有 \`devices\` 数据分组展示，失败明细继续读取 \`failures\`。\`App\` 对三个终态统一按 session 去重打开结果弹窗。

在三种 locale 中增加完全一致的键集合，并让 \`DevicePanel\`/\`StatusBadge\` 支持 \`AWAITING_DISCOVERY_CONFIRMATION\`、\`PARTIAL_SUCCESS\`、\`IGNORED\`。

- [ ] **Step 4: 运行前端测试直至通过**

Run:

\`\`\`powershell
npm --prefix frontend test -- app_failure.test.js dashboard.test.js
\`\`\`

Expected: PASS。

- [ ] **Step 5: 检查并提交本任务差异**

Run:

\`\`\`powershell
git diff --check
git status --short --branch
git worktree list
\`\`\`

只暂存本任务文件后提交：

\`\`\`powershell
git add frontend/src/App.vue frontend/src/components/Dashboard.vue frontend/src/components/FailureDialog.vue frontend/src/components/DevicePanel.vue frontend/src/components/StatusBadge.vue frontend/src/locales/zh-CN.js frontend/src/locales/en-US.js frontend/src/locales/ar-SA.js frontend/src/styles/app.css tests/app_failure.test.js tests/dashboard.test.js
git commit -m "feat(distribution): show all terminal result dialogs"
\`\`\`

### Task 6: 全量回归与需求一致性检查

**Files:**
- Verify: \`docs/requirements/01-CPDS-requirements.md\`
- Verify: \`docs/requirements/03-CPDS-CPDC-interaction-requirements.md\`
- Verify: all files changed in Tasks 1–5

- [ ] **Step 1: 运行 Go 全量测试**

Run:

\`\`\`powershell
go test ./...
\`\`\`

Expected: PASS，无失败包。

- [ ] **Step 2: 运行前端全量测试与构建**

Run:

\`\`\`powershell
npm --prefix frontend test
npm --prefix frontend run build
\`\`\`

Expected: Vitest 全部通过，Vite 构建成功。

- [ ] **Step 3: 验证需求文档同步和差异质量**

Run:

\`\`\`powershell
git diff --check
git diff -- docs/requirements/01-CPDS-requirements.md docs/requirements/03-CPDS-CPDC-interaction-requirements.md
Compare-Object (Get-Content "D:\CPD\CPDS\docs\requirements\01-CPDS-requirements.md") (Get-Content "D:\CPD\CPDC\docs\requirements\01-CPDS-requirements.md")
Compare-Object (Get-Content "D:\CPD\CPDS\docs\requirements\03-CPDS-CPDC-interaction-requirements.md") (Get-Content "D:\CPD\CPDC\docs\requirements\03-CPDS-CPDC-interaction-requirements.md")
\`\`\`

Expected: \`git diff --check\` 无输出，两个 \`Compare-Object\` 均无输出。

- [ ] **Step 4: 核对最终工作树和提交范围**

Run:

\`\`\`powershell
git status --short --branch
git worktree list
git log --oneline --decorate -6
\`\`\`

Expected: 位于 \`D:\CPD\CPDS\` 的 \`feature/discovery-mismatch-wails2\` 分支；无本实现遗留的未提交代码，用户原有的 \`docs/requirements/02-CPDC-requirements.md\`、\`AGENTS.md\` 等无关变更未被暂存或提交。
