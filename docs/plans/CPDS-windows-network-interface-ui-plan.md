# CPDS Windows Business Network Interface UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use test-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让无需启动参数的 `CPDS.exe`在右侧节点标题下枚举、选择、刷新并持久化单一业务有线网卡，且Distribution使用该选择；CCU行为保持不变。

**Architecture:** Go协议层继续负责候选接口过滤，服务层负责校验并保存Windows当前选择，Wails绑定只暴露枚举和选择方法。Vue由独立的网卡栏组件负责呈现，`App.vue`负责Wails调用、自动选择和 `localStorage`持久化；CCU浏览器不创建该状态，也不显示该组件。

**Tech Stack:** Go 1.22、Wails v2、Vue 3 Composition API、vue-i18n、Vitest、Go testing。

---

### Task 1: 后端网卡选择状态

**Files:**
- Modify: `internal/service/manager.go`
- Modify: `cmd/cpds-desktop/app_windows.go`
- Modify: `cmd/cpds-desktop/main_windows.go`
- Test: `tests/multi_interface_test.go`

- [ ] **Step 1: 写失败测试**

在 `tests/multi_interface_test.go`增加测试，要求Windows入口不再包含 `flag.String("interface"`，并验证 `Manager.SetInterfaceName`允许空名称清除选择、接受候选名称并拒绝非候选名称。

- [ ] **Step 2: 运行测试确认失败**

Run: `go test ./tests -run "Test(WindowsLauncherNeedsNoInterfaceArgument|ManagerSelectsBusinessInterface)" -count=1`

Expected: FAIL，因为入口仍解析参数且Manager尚无选择方法。

- [ ] **Step 3: 写最小实现**

在Manager增加 `SetInterfaceName(name string) error`，用 `protocol.AvailableWiredInterfaces()`验证名称；获得锁后再次检查活动状态并保存名称。Wails `DesktopApp`增加 `ListNetworkInterfaces()`与 `SelectNetworkInterface(name)`，错误沿用结构化 `errorCode/params`。Windows `main`删除 `flag`和 `InterfaceName`启动配置。

- [ ] **Step 4: 运行后端测试**

Run: `go test ./tests -run "Test(WindowsLauncherNeedsNoInterfaceArgument|ManagerSelectsBusinessInterface)" -count=1`

Expected: PASS。

### Task 2: 前端选择规则和Wails服务

**Files:**
- Create: `frontend/src/services/networkInterfaces.js`
- Modify: `frontend/src/services/cpds.js`
- Test: `tests/network_interface.test.js`

- [ ] **Step 1: 写失败测试**

覆盖单候选自动选择、有效持久化值恢复、无效值不选、多候选手动选择写入 `cpds.networkInterface`、刷新后已选项失效时清空，以及非Wails环境不枚举。

- [ ] **Step 2: 运行测试确认失败**

Run: `npm test -- --run ../tests/network_interface.test.js`

Expected: FAIL，因为服务模块和Wails方法尚不存在。

- [ ] **Step 3: 写最小实现**

`networkInterfaces.js`导出 `NETWORK_INTERFACE_STORAGE_KEY`、纯函数 `resolveNetworkInterface(interfaces, storedName)`；`cpds.js`导出 `isDesktop()`、`listNetworkInterfaces()`和 `selectNetworkInterface(name)`，复用现有结构化结果处理。

- [ ] **Step 4: 运行前端服务测试**

Run: `npm test -- --run ../tests/network_interface.test.js`

Expected: PASS。

### Task 3: 右侧业务网卡栏

**Files:**
- Create: `frontend/src/components/NetworkInterfaceBar.vue`
- Modify: `frontend/src/components/DevicePanel.vue`
- Modify: `frontend/src/components/Dashboard.vue`
- Modify: `frontend/src/App.vue`
- Modify: `frontend/src/styles/app.css`
- Modify: `frontend/src/locales/zh-CN.js`
- Modify: `frontend/src/locales/en-US.js`
- Modify: `frontend/src/locales/ar-SA.js`
- Test: `tests/dashboard.test.js`
- Test: `tests/i18n.test.js`

- [ ] **Step 1: 写失败测试**

在桌面模式断言标题下一行依次出现网卡标签、下拉框、刷新和下发按钮；选择与刷新事件可到达父组件；活动会话时下拉和刷新禁用；浏览器模式不显示该行且保留原标题栏下发按钮；三套语言资源键一致。

- [ ] **Step 2: 运行测试确认失败**

Run: `npm test -- --run ../tests/dashboard.test.js ../tests/i18n.test.js`

Expected: FAIL，因为业务网卡栏尚不存在。

- [ ] **Step 3: 写最小实现**

新增专用组件并使用现有 `.button`、颜色令牌和逻辑CSS属性。桌面模式把“下发”放入新行，CCU模式保留原位置；不修改阶段条、进度条和设备卡片样式。`App.vue`启动时枚举并执行自动选择规则，用户选择后调用Go并写入localStorage，失败走现有三语弹窗。

- [ ] **Step 4: 运行前端测试**

Run: `npm test -- --run ../tests/dashboard.test.js ../tests/i18n.test.js ../tests/network_interface.test.js`

Expected: PASS。

### Task 4: 全量验证

**Files:**
- Verify: `frontend/`
- Verify: `internal/`
- Verify: `cmd/`

- [ ] **Step 1: 格式化**

Run: `gofmt -w cmd/cpds-desktop/main_windows.go cmd/cpds-desktop/app_windows.go internal/service/manager.go tests/multi_interface_test.go`

- [ ] **Step 2: 运行全部测试**

Run: `go test ./...`

Run: `npm test`

Expected: 两组命令均PASS且无失败测试。

- [ ] **Step 3: 构建前端和Windows程序**

Run: `npm run build`

Run: `powershell -ExecutionPolicy Bypass -File build/scripts/build.ps1`

Expected: Vue构建成功，`build/dist/bin/CPDS.exe`与 `build/dist/bin/CPDS-CCU`生成成功。
