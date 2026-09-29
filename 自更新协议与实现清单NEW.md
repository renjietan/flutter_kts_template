# 自更新协议与实现清单（NEW）

## 一、概述

- CPDS（`flutter_kts_template`，Flutter）是自更新服务端：负责安装包上传、扫描、认证、版本校验、传输、校验、写入、回执汇总。
- CPDC（`CPDC-main`，Go）是设备端客户端：负责响应命令、收包组装、校验、写入安装、重启替换、启动回执。
- 本协议与现有 `cpd.proto` 完全独立，使用独立 UDP 端口与独立消息格式。
- 所有上行回复（除 `Scan:success`）统一携带二进制设备标识 ID。
- 字节序：全部大端序（uint16BE / uint32BE）。

## 二、设备类型与安装文件映射

| 安装文件名称 | 设备类型 | 基础配置文件 | 独有配置文件 |
|---|---|---|---|
| CPDC-CCU | CCU(主控板) | cpdc_config.json | cpdc_config.CCU.json |
| CPDC-CCU-Audio | CCUAudio(音控板) | cpdc_config.json | cpdc_config.CCUAudio.json |
| CPDC-MultibandRadio | MMR200(电台) | cpdc_config.json | cpdc_config.MMR200.json |
| CPDC-HF | MR9360(电台) | cpdc_config.json | cpdc_config.MR9360.json |
| CPDC-MultibandHandheld | PMR200(电台) | cpdc_config.json | cpdc_config.PMR200.json |
| CPDC-VehInte | VehInter(车通) | cpdc_config.json | cpdc_config.VehInter.json |

- 设备类型 = 本地 `cpdc_config.<类型>.json` 文件名里的 `<类型>` 占位符（排除 `cpdc_config.json`）。
- 安装文件按「非 `.ini` / `.json` 扩展名」识别，名称大小写不影响匹配。
- `Server` / `IEC` / `SmallHandheld` 无对应更新文件夹；认证阶段 CPDS 直接跳过、不加入设备表。

## 三、UDP 端口

| 端 | 端口 | 用途 |
|---|---|---|
| CPDC | 39003 | 监听（接收 CPDS 广播命令） |
| CPDS | 39004 | 监听（接收 CPDC 回复） |

## 四、传输阶段的按钮状态（CPDS UI）

| 阶段 | 进度条右侧 | 底部按钮 |
|---|---|---|
| 发现 / 认证 / 版本校验 | 无 | 无 |
| 传输（未开始） | 无 | 【开始】【取消】 |
| 传输（进行中） | 【暂停】 | 【取消】 |
| 传输（已暂停） | 【继续】 | 【取消】 |
| 校验 valid（运行中） | 无 | 【取消】 |
| 校验 valid（成功） | 无 | 无 |
| 写入 write（运行中） | 无 | 无 |
| 写入 write（成功） | 无 | 无 |
| 回执 update（等待中） | 无 | 无 |
| 认证失败（N == 0） | 无 | 【取消】【重新认证】 |
| 版本校验失败（0 回复） | 无 | 【取消】【重新版本校验】 |
| 校验失败 | 无 | 【取消】【重新校验】 |
| 写入失败 | 无 | 【取消】【重新写入】 |
| 完成 | 无 | 【关闭】 |

## 五、公用协议

### 5.1 设备标识 ID

```text
ID = [类型字节长度 uint16BE] + [类型 UTF-8] + [IP字节长度 uint16BE] + [IP UTF-8]
```

### 5.2 通用规则

- 下行指令（CPDS → CPDC）不带 ID。
- 上行回复（CPDC → CPDS）除 `Scan:success` 外都带 ID。
- 除 `Scan` 外，所有发送/等待都带重试：初始 1 次 + 重试 2 次 = 最多 3 次。
- `packet:` 分包载荷最大 1381 字节，整包不超过 1400 字节。

## 六、协议

### 6.1 扫描 Scan

#### CPDS 发送

| 指令 | 指令前缀（字节长度） | 重试次数、等待秒数 | 超时后的表现 |
|---|---|---|---|
| `Scan` | `"Scan"`（4 字节） | 每秒 1 次，共 10 秒（不重试） | 10 秒结束：0 台提示「未扫描到设备」；≥1 台进入更新弹窗 |

逻辑：

1. 扫描计数按 UDP 数据报来源 IP 去重；`Scan:success` 不带 ID。
2. 扫到 ≥1 台可点【下一步】提前结束：停止计时器、不再发 `Scan`、丢弃后续 `Scan:success`。

#### CPDC 返回

| 指令 | 指令前缀（字节长度） | 动作 |
|---|---|---|
| `Scan:success` | `"Scan:success"`（12 字节） | 全局复位后立即回复 |

逻辑：

1. 收到 `Scan` → 终止在途任务、清空 assembler、复位目标版本、删除回执 marker → 回 `Scan:success`。

### 6.2 认证 auth

#### CPDS 发送

| 指令 | 指令前缀（字节长度） | 重试次数、等待秒数 | 超时后的表现 |
|---|---|---|---|
| `auth` | `"auth"`（4 字节） | 3 个独立 5 秒窗口 | 3 窗口后 N == 0 → 认证失败；N > 0 → 进入版本校验 |

逻辑：

1. 每个窗口单独广播 `auth` 并收集 `authAck`，按「类型#IP」去重（过滤 `Server`/`IEC`/`SmallHandheld`）。
2. `N >= 扫描设备数` → 认证成功，进入版本校验。
3. `N < 扫描设备数` → 进入下一窗口重试。
4. 3 个窗口后：`N == 0` → 认证步骤红 + 提示「认证失败：设备认证数量为 0」+【取消】【重新认证】；`N > 0` → 认证转绿，进入版本校验。

#### CPDC 返回

| 指令 | 指令前缀（字节长度） | 参数1（字节长度） |
|---|---|---|
| `authAck` | `"authAck:"`（8 字节） | ID（4 + 类型长度 + IP 长度） |

逻辑：

1. 收到 `auth` → 无条件回 `authAck:<ID>`，ID 类型/IP 来自本地设备类型和 IP。

### 6.3 版本校验 version

#### CPDS 发送

| 指令 | 指令前缀（字节长度） | 参数1（字节长度） | 重试次数、等待秒数 | 超时后的表现 |
|---|---|---|---|---|
| `version:` | `"version:"`（8 字节） | 目标版本号（变长 UTF-8） | 3 个独立 5 秒窗口 | 0 回复 → 版本校验失败；>0 回复 → 进入传输 |

逻辑：

1. 每个窗口广播 `version:<目标版本>`，收集 `version_ok` / `version_fail`，按「类型#IP」去重（`version_fail` 也算已回复）。
2. 回复数 `N >= 设备表行数` → 版本校验成功。
3. `N < 设备表行数` → 下一窗口重试。
4. 3 个窗口后：`N == 0` → 版本校验步骤红 +【取消】【重新版本校验】；`N > 0` → 转绿，未回复设备标记「无法获取」。
5. 版本比较在 CPDS：当前版本 == 目标版本 → 已最新；不等 → 需更新。

#### CPDC 返回成功

| 指令 | 指令前缀（字节长度） | 参数1（字节长度） | 参数2（字节长度） |
|---|---|---|---|
| `version_ok` | `"version_ok:"`（11 字节） | ID | 当前版本（变长 UTF-8） |

#### CPDC 返回错误

| 指令 | 指令前缀（字节长度） | 参数1 | 参数2 | 动作 | 原因（中文） |
|---|---|---|---|---|---|
| `version_fail` | `"version_fail:"`（13 字节） | ID | `format` | 回失败 | 版本号格式非法 |

逻辑：

1. 收到 `version:` → 校验后面版本号格式 `^\d+\.\d+\.\d+\.\d+$`。
2. 合法 → 缓存目标版本，实时重读设备 `cpdc_config.json` 当前版本，回 `version_ok:<ID><当前版本>`。
3. 非法 → 回 `version_fail:<ID><format>`。

### 6.4 传输前置 file

#### CPDS 发送

| 指令 | 指令前缀（字节长度） | 参数1（字节长度） | 参数2（字节长度） | 参数3（字节长度） | 参数4（字节长度） | 重试次数、等待秒数 | 超时后的表现 |
|---|---|---|---|---|---|---|---|
| `file:` | `"file:"`（5 字节） | CRC32 整 ZIP（4，大端） | 包数量（4，大端） | 文件总字节（4，大端） | 文件名（变长 UTF-8） | 3 秒超时 × 3 次 | 3 次未收齐全部设备 `fileAck` → 终止「传输前置指令超时」 |

逻辑：

1. 点击【开始】后，对「需更新」设备按类型去重打包成**一个 ZIP**。
2. 广播 `file:`，等所有目标设备都回 `fileAck`。

#### CPDC 返回

| 指令 | 指令前缀（字节长度） | 参数1 | 参数2 | 参数3 | 参数4 | 参数5 |
|---|---|---|---|---|---|---|
| `fileAck` | `"fileAck:"`（8 字节） | ID | CRC32 整 ZIP（4，大端） | 包数量（4，大端） | 文件总字节（4，大端） | 文件名（变长） |

逻辑：

1. 收到 `file:` → 解析头（CRC32、包数量>0、总字节、文件名非空）→ 记录组装元信息 → 回 `fileAck`。

### 6.5 传输分包 packet

#### CPDS 发送

| 指令 | 指令前缀（字节长度） | 参数1（字节长度） | 参数2（字节长度） | 参数3（字节长度） | 参数4（字节长度） | 重试次数、等待秒数 | 超时后的表现 |
|---|---|---|---|---|---|---|---|
| `packet:` | `"packet:"`（7 字节） | CRC32 本次分包（4，大端） | 包号（4，大端，从 1） | 分包长度（4，大端） | 分包数据（≤1381 字节） | 每个分包 3 个独立 3 秒窗口 | 3 窗口耗尽 → 终止「传输分包超时」 |

逻辑：

1. 逐包发送；每个分包等所有目标设备都回 `packet_ok` 才算成功。
2. `packet_fail` 等整窗口结束后再处理：
   - `sequence:<S>`（优先，取最小 S）→ 游标拉回 S，从 S 顺序重发。
   - `length` / `crc` → 重发当前分包（最多 3 次）。

#### CPDC 返回成功

| 指令 | 指令前缀（字节长度） | 参数1 | 参数2 | 参数3 | 参数4 |
|---|---|---|---|---|---|
| `packet_ok` | `"packet_ok:"`（10 字节） | ID | CRC32 本次分包（4，大端） | 包号（4，大端） | 分包长度（4，大端） |

#### CPDC 返回错误

| 指令 | 指令前缀（字节长度） | 参数1 | 参数2 | 参数3 | 参数4 | 参数5 | 动作 | 原因（中文） |
|---|---|---|---|---|---|---|---|---|
| `packet_fail` | `"packet_fail:"`（12 字节） | ID | CRC32 本次分包（4） | 包号（4） | 分包长度（4） | `length` / `crc` / `sequence:<S>` | 回失败 | 分包长度错误 / CRC 校验失败 / 分包顺序错误（缺包） |

逻辑：

1. 收到 `packet:` → 包号范围检查：包号 == 0 或 > 包数量 → 丢弃。
2. 包号 < 期望下一包（重复包）→ 重发 `packet_ok`，不覆盖、不计数。
3. 包号 > 期望下一包（跳号）→ 回 `packet_fail:sequence:<期望包号>`。
4. 长度不符 → `packet_fail:length`；CRC32 不符 → `packet_fail:crc`。
5. 通过 → 写入 assembler 下标（包号-1），计数，回 `packet_ok`。收齐后不自动校验，等 `valid:`。

### 6.6 校验 valid

#### CPDS 发送

| 指令 | 指令前缀（字节长度） | 参数1 | 参数2 | 参数3 | 参数4 | 重试次数、等待秒数 | 超时后的表现 |
|---|---|---|---|---|---|---|---|
| `valid:` | `"valid:"`（6 字节） | CRC32 整 ZIP（4，大端） | 包数量（4，大端） | 文件总字节（4，大端） | 文件名（变长） | 3 个独立 5 秒窗口 | 仍有 fail/超时 → 校验失败 +【重新校验】 |

逻辑：

1. 广播 `valid:<file头>`，等所有目标设备回 `valid_ok`。
2. `valid_fail` / 超时触发重试；3 窗口后仍有 fail/超时 → 步骤红 +【取消】【重新校验】。
3. 全部 `valid_ok` → 进入 write。

#### CPDC 返回成功

| 指令 | 指令前缀（字节长度） | 参数1 |
|---|---|---|
| `valid_ok` | `"valid_ok:"`（9 字节） | ID |

#### CPDC 返回错误

| 指令 | 指令前缀（字节长度） | 参数1 | 参数2 | 动作 | 原因（中文） |
|---|---|---|---|---|---|
| `valid_fail` | `"valid_fail:"`（11 字节） | ID | `size` / `crc` / `zip` / `mismatch` | 回失败 | 文件大小不符 / CRC 校验失败 / 解压失败 / 文件头不匹配 |

逻辑：

1. 比对 `valid:` 的 file 头与 `file:` 的头；不一致 → `valid_fail:mismatch`。
2. 一致 → 组装 ZIP 校验：总字节 / CRC32 / 可解压 → `valid_ok` 或 `valid_fail:<size|crc|zip>`。

### 6.7 写入 write

#### CPDS 发送

| 指令 | 指令前缀（字节长度） | 参数1 | 参数2 | 参数3 | 参数4 | 重试次数、等待秒数 | 超时后的表现 |
|---|---|---|---|---|---|---|---|
| `write:` | `"write:"`（6 字节） | CRC32 整 ZIP（4，大端） | 包数量（4，大端） | 文件总字节（4，大端） | 文件名（变长） | 3 个独立 15 秒窗口 | 仍有 fail/超时 → 写入失败 +【重新写入】 |

逻辑：

1. 广播 `write:<file头>`，等所有目标设备回 `write_ok`。
2. `write_fail` / 超时触发重试；3 窗口后仍有 fail/超时 → 步骤红 +【取消】【重新写入】。
3. 全部 `write_ok` → 进入回执（30 秒被动等待）。

#### CPDC 返回成功

| 指令 | 指令前缀（字节长度） | 参数1 | 动作 |
|---|---|---|---|
| `write_ok` | `"write_ok:"`（9 字节） | ID | 连发 3 次，间隔 1 秒，然后退出旧进程 |

#### CPDC 返回错误

| 指令 | 指令前缀（字节长度） | 参数1 | 参数2 | 动作 | 原因（中文） |
|---|---|---|---|---|---|
| `write_fail` | `"write_fail:"`（11 字节） | ID | 原因码 | 回失败 | 见「七、错误码」 |

逻辑：

1. 比对 file 头；不一致 → `write_fail:mismatch`。
2. 一致 → 清理残留 → 覆盖 JSON / INI / marker / version → 写 staging `install_cpdc/new_exe` → 写 `install_cpdc/finalize_params.json`。
3. spawn 自身 `--self-update-finalize --params <paramsPath>`：失败 → `write_fail:restart_spawn_fail`（不退出、可重试）。
4. spawn 成功 → `write_ok` 连发 3 次、间隔 1 秒 → `exitNow(0)` 退出旧进程。
5. finalize 进程在旧进程退出后：`rename(old_exe → <exe>.<版本>.bak)` → `rename(new_exe → old_exe)` → 启动新进程 → 成功清理；失败写 `install_cpdc/finalize_fail` 并回滚启动旧 exe。

### 6.8 回执 update

#### CPDS 被动等待

| 方向 | 等待时间 | 结束条件 |
|---|---|---|
| 被动等待 | 30 秒 | 收集「写入成功」设备的 `update_ok` / `update_fail`，汇总后进入 finished |

逻辑：

1. 只统计「写入成功」设备的 update 结果；`write_fail` / `write 超时`设备不参与。
2. `update_ok` → 更新成功(vX)；`update_fail` → 更新失败(原因)；30 秒未回 → 回执超时。
3. 汇总「更新完成：成功 X 台，失败 Y 台，超时 Z 台」+【关闭】。

#### CPDC 返回成功

| 指令 | 指令前缀（字节长度） | 参数1 | 参数2 |
|---|---|---|---|
| `update_ok` | `"update_ok:"`（10 字节） | ID | 新版本（变长） |

#### CPDC 返回错误

| 指令 | 指令前缀（字节长度） | 参数1 | 参数2 | 动作 | 原因（中文） |
|---|---|---|---|---|---|
| `update_fail` | `"update_fail:"`（12 字节） | ID | `version_read_error` / `version_mismatch` / `finalize_fail` | 回失败 | 读取版本失败 / 版本不匹配 / 替换可执行文件失败 |

逻辑：

1. 新进程启动后读回执 marker；若 `install_cpdc/finalize_fail` 存在 → 优先回 `update_fail:finalize_fail`。
2. 否则读设备当前版本：读失败 → `version_read_error`；与 marker 目标版本不等 → `version_mismatch`；相等 → `update_ok:<新版本>`。
3. `update_ok` / `update_fail` 连发 3 次、间隔 1 秒，然后删除 marker 和失败标记。

## 七、错误码

| 码 | 阶段 | 中文 | English | العربية |
|---|---|---|---|---|
| `format` | version_fail | 版本号格式非法 | Invalid version format | تنسيق الإصدار غير صالح |
| `length` | packet_fail | 分包长度错误 | Packet length error | خطأ في طول الحزمة |
| `crc` | packet_fail / valid_fail | 校验失败（CRC） | CRC verification failed | فشل التحقق CRC |
| `sequence:<S>` | packet_fail | 分包顺序错误（缺包） | Packet sequence error | خطأ في تسلسل الحزمة |
| `size` | valid_fail | 文件大小不符 | File size mismatch | عدم تطابق حجم الملف |
| `zip` | valid_fail | 解压失败 | Decompression failed | فشل فك الضغط |
| `mismatch` | valid_fail / write_fail | 文件头不匹配 | File header mismatch | عدم تطابق رأس الملف |
| `unzip_fail` | write_fail | 解压 ZIP 失败 | Unzip failed | فشل فك ضغط الملف |
| `type_dir_not_found:<类型>` | write_fail | 找不到设备类型文件夹 | Device type directory not found | لم يتم العثور على مجلد نوع الجهاز |
| `install_file_not_found` | write_fail | 找不到安装文件 | Install file not found | لم يتم العثور على ملف التثبيت |
| `install_file_multiple` | write_fail | 存在多个安装文件 | Multiple install files | توجد ملفات تثبيت متعددة |
| `read_config_fail:<路径>` | write_fail | 读取配置失败 | Read config failed | فشل قراءة التكوين |
| `executable_path_fail` | write_fail | 获取运行程序路径失败 | Get executable path failed | فشل الحصول على مسار البرنامج |
| `overwrite_binary_open_fail:<路径>` | write_fail | 写新 exe：打开源文件失败 | Stage binary: open source failed | فشل فتح الملف المصدر للبرنامج |
| `overwrite_binary_temp_fail:<路径>` | write_fail | 写新 exe：写临时文件失败 | Stage binary: temp write failed | فشل كتابة الملف المؤقت للبرنامج |
| `overwrite_binary_rename_fail:<路径>` | write_fail | 写新 exe：改名替换失败 | Stage binary: rename failed | فشل إعادة تسمية البرنامج |
| `overwrite_config_open_fail:<路径>` | write_fail | 覆盖配置：打开源文件失败 | Overwrite config: open source failed | فشل فتح الملف المصدر للتكوين |
| `overwrite_config_temp_fail:<路径>` | write_fail | 覆盖配置：写临时文件失败 | Overwrite config: temp write failed | فشل كتابة الملف المؤقت للتكوين |
| `overwrite_config_rename_fail:<路径>` | write_fail | 覆盖配置：改名替换失败 | Overwrite config: rename failed | فشل إعادة تسمية التكوين |
| `overwrite_ini_open_fail:<路径>` | write_fail | 覆盖 ini：打开源文件失败 | Overwrite ini: open source failed | فشل فتح الملف المصدر لـ ini |
| `overwrite_ini_temp_fail:<路径>` | write_fail | 覆盖 ini：写临时文件失败 | Overwrite ini: temp write failed | فشل كتابة الملف المؤقت لـ ini |
| `overwrite_ini_rename_fail:<路径>` | write_fail | 覆盖 ini：改名替换失败 | Overwrite ini: rename failed | فشل إعادة تسمية ini |
| `write_marker_fail:<路径>` | write_fail | 写回执标记失败 | Write receipt marker failed | فشل كتابة علامة الاستلام |
| `version_write_fail:<路径>` | write_fail | 回填版本失败 | Write version failed | فشل كتابة الإصدار |
| `mkdir_fail:<路径>` | write_fail | 创建目录失败 | Create directory failed | فشل إنشاء الدليل |
| `write_params_fail:<路径>` | write_fail | 写重启参数失败 | Write finalize params failed | فشل كتابة معلمات إعادة التشغيل |
| `restart_spawn_fail` | write_fail | 启动脚本失败 | Restart script failed | فشل تشغيل السكربت |
| `version_read_error` | update_fail | 读取版本失败 | Failed to read version | فشل قراءة الإصدار |
| `version_mismatch` | update_fail | 版本不匹配 | Version mismatch | عدم تطابق الإصدار |
| `finalize_fail` | update_fail | 替换可执行文件失败 | Failed to replace executable | فشل استبدال الملف التنفيذي |

> 保留码（CPDS 已支持三语翻译，但当前 CPDC 实现暂未生成）：`no_header`、`missing_packet:<包号列表>`。

## 八、文件目录清单

### 8.1 CPDS（Flutter）

统一位于应用文档目录 `install/`（Windows 示例 `C:\Users\<用户>\Documents\CPD\install`）。

| 文件/目录 | 说明 |
|---|---|
| `install/<时间戳>.zip` | 用户上传的原始 ZIP |
| `install/.staging_<时间戳>` | 上传解压中转目录，成功后 rename 到正式目录再删除 |
| `install/<时间戳>/<设备类型>/cpdc_config.json` | 上传时回写根节点 `version` 的目标版本 |
| 内存打包 ZIP | 传输阶段按设备类型去重后，在内存生成一个 ZIP，不落盘 |

### 8.2 CPDC（Go）

运行目录 = CPDC 二进制所在目录；配置目录 = `--config-path` 解析结果。

| 文件/目录 | 说明 |
|---|---|
| `cpdc_config.json` | 设备基础配置；write 阶段覆盖，并回填 `version` |
| `cpdc_config.<类型>.json` | 设备类型独有配置；write 阶段按需覆盖 |
| `ReReadJson.ini` 或 `ReReadjsonPath` 指向文件 | write 阶段按需覆盖 |
| `系统临时目录/cpdc-update-<随机串>` | write 阶段解压 ZIP 的临时目录，流程结束删除 |
| `<运行目录>/install_cpdc/new_exe` | write 阶段暂存的新可执行文件 |
| `<运行目录>/install_cpdc/finalize_params.json` | finalize 参数文件 |
| `<运行目录>/install_cpdc/finalize_fail` | finalize 失败标记 |
| `<运行目录>/.cpdc_update_receipt.json` | 回执 marker，内容 `{"version","ip"}` |
| `<运行目录>/<exe>.<版本>.bak` | finalize 期间旧 exe 的备份，成功启动后删除 |
| `<运行目录>/logs/cpdc_restart.log` | finalize 日志，每次覆盖 |
| `<运行目录>/logs/cpdc_<版本>.log` | 新进程运行日志，每次覆盖 |
| `<目标目录>/.cpdc-write-*` | 原子写临时文件（marker、回填 version） |
| `<目标目录>/.cpdc-copy-*` | 原子拷贝临时文件（JSON、INI、new_exe） |
