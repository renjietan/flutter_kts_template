# CPDS 实施计划

1. 建立 Go module、Vue/Vite/Wails 配置和集中测试入口。
2. 先写通信包解析失败测试，实现 ZIP 安全检查、JSON 索引、节点树和设备映射。
3. 先写协议与状态机失败测试，生成 Proto 代码，实现 Magic UDP 编解码、双发、节流、超时与 Distribution 状态机。
4. 先写 API 失败测试，实现上传、解析、选择节点、开始下发、快照查询与 WebSocket 推送。
5. 先写国际化和组件失败测试，实现三语资源、持久化、RTL 与 Figma 页面。
6. 运行 Go 单元/竞态测试、前端测试、前端构建、Windows/CCU 编译检查和协议尺寸验证。
