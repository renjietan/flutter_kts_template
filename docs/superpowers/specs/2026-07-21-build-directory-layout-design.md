# CPDS 构建目录整理设计

## 目标

在不新增自启动逻辑、运行配置或编译器的前提下，把 CPDS 的构建相关文件统一整理到根目录 `build/` 下，并在迁移校验完成后删除旧目录。

本次仅调整 CPDS 仓库目录和路径引用，不修改 CPDS/CPDC 协议、业务逻辑或 CPDC 代码。

## 已确认约束

- 根目录 `.tools/`及其内容保持原位，不迁移、不删除。
- `build/compiler/`只作为空目录占位，通过 `.gitkeep`纳入版本控制。
- `build/dist/install/`和 `build/dist/config/`只作为空目录占位，通过 `.gitkeep`纳入版本控制。
- 不新增自启动脚本或默认配置文件。
- 迁移成功并确认旧目录为空后，删除根目录旧 `scripts/`和旧 `build/bin/`目录。
- 不使用递归批量删除。只删除已经核对为空的明确目录；若目录中出现未纳入迁移的文件，停止删除并保留现场。

## 目标目录

```text
CPDS/
├─ .tools/                         # 保持不变
└─ build/
   ├─ scripts/
   │  ├─ build.bat
   │  ├─ build.ps1
   │  └─ test.ps1
   ├─ compiler/
   │  └─ .gitkeep                 # 空目录占位
   └─ dist/
      ├─ bin/                     # 生成的 CPDS.exe、CPDS-CCU 及其同级运行数据
      ├─ install/
      │  └─ .gitkeep             # 空目录占位
      └─ config/
         └─ .gitkeep             # 空目录占位
```

## 迁移映射

| 现有位置 | 目标位置 | 处理方式 |
|---|---|---|
| `scripts/build.bat` | `build/scripts/build.bat` | 移动并保持批处理入口行为 |
| `scripts/build.ps1` | `build/scripts/build.ps1` | 移动并修正仓库根目录计算及产物路径 |
| `scripts/test.ps1` | `build/scripts/test.ps1` | 移动并修正仓库根目录计算 |
| `build/bin/CPDS.exe` | `build/dist/bin/CPDS.exe` | 移动现有产物；后续构建直接输出到新路径 |
| `build/bin/CPDS-CCU` | `build/dist/bin/CPDS-CCU` | 移动现有产物；后续构建直接输出到新路径 |
| `build/bin/runtime/` | `build/dist/bin/runtime/` | 整体保留现有日志和上传副本，随可执行文件迁移 |
| `.tools/` | `.tools/` | 保持原位 |

迁移时先建立目标目录，再逐项移动明确文件或目录并核对目标存在。只有 `scripts/`和 `build/bin/`均已确认为空，才分别删除这两个旧目录。

## 路径引用调整

- `build/scripts/build.ps1`以自身位置向上两级解析仓库根目录，并将两个应用程序输出到 `build/dist/bin/`。
- `build/scripts/test.ps1`以自身位置向上两级解析仓库根目录，继续执行原有前端测试、前端构建、Go 测试和 `go vet`。
- `build/scripts/build.bat`继续通过同目录的 `build.ps1`启动构建，无需兼容旧入口。
- `.gitignore`把旧 `/build/bin/`规则改为 `/build/dist/bin/`；`/.tools/`规则保持不变。
- README、自动化测试和仓库内仍代表当前用法的文档统一改用 `build/scripts/...`和 `build/dist/bin/...`。
- CPDC 需求文档中指向 CPDC 自身 `scripts/build-audio.ps1`的内容不属于 CPDS 路径，不修改。

## 兼容性与错误处理

- 不保留根目录 `scripts/`转发脚本，避免形成两个构建入口。
- 调整后旧命令 `scripts/build.ps1`和 `scripts/test.ps1`不再可用，统一使用 `build/scripts/build.ps1`和 `build/scripts/test.ps1`。
- 移动任何现有产物或运行数据失败时立即停止，不删除来源文件和旧目录。
- 若目标位置已有同名但内容不同的文件，不覆盖，先报告冲突。
- 构建失败时保留已有产物和日志，行为与现有脚本一致。

## 测试与验收

1. 先修改构建脚本测试，使其读取 `build/scripts/`并校验新输出路径；在迁移前运行，确认测试因新路径尚不存在而失败。
2. 完成脚本迁移和路径调整后，运行该定向测试并确认通过。
3. 运行 `build/scripts/test.ps1`，要求前端测试与构建、Go 测试和 `go vet`全部通过。
4. 运行 `build/scripts/build.ps1`，确认生成 `build/dist/bin/CPDS.exe`和 `build/dist/bin/CPDS-CCU`。
5. 确认 `.tools/`内容和路径未变化。
6. 确认 `build/compiler/`、`build/dist/install/`和 `build/dist/config/`存在且除占位文件外无新增内容。
7. 确认旧根目录 `scripts/`和旧 `build/bin/`已删除。
8. 扫描当前入口文档、测试和脚本，确认不存在指向 CPDS 旧路径的有效引用。
