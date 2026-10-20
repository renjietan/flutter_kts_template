# cpd_lints

CPDS 应用的响应式布局防回归规则集，以 Dart 官方 `analysis_server_plugin`
(Dart 3.10 / Flutter 3.38 起支持) 方式实现，替代已停止维护且不兼容
analyzer 10 的 `custom_lint`。

## 规则

- `hardcoded_dimension`（warning，默认启用）：`width` / `height` / `size` /
  `fontSize` / `minWidth` / `maxWidth` / `minHeight` / `maxHeight` / `left` /
  `right` / `top` / `bottom` / `horizontal` / `vertical` / `radius` 等具名参数
  直接使用非零数字字面量时告警；同时覆盖 `EdgeInsets(...)`、`Size(...)`、
  `Offset(...)`、`BorderRadius.circular(...)`、`Radius.circular(...)` /
  `Radius.elliptical(...)` 的位置参数。要求改用 `.w` / `.h` / `.sp` / `.r`
  单位扩展。

## 接入

在应用根目录的 `analysis_options.yaml` 顶层加入：

```yaml
plugins:
  cpd_lints:
    path: third_party/cpd_lints
```

修改 `plugins` 段后需重启 Dart Analysis Server。
