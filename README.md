### 版本说明
- Flutter - 3.38.10
- Gradle - 8.14-all
- AGP - 8.11.1
- ktolin - 2.2.20

### 运行
- 使用 Android Studio 单独打开 Android 文件夹，此时软件将自动构建 Grade
- 构建完成后，重新打开项目即可
### 打包
- flutter build apk --release --split-per-abi
### adb
- 文件拷贝: 通过ADB将本机文件拷贝到【模拟器】
  - adb push "C:\Users\Administrator\Documents\CPD\uploads\[2026-07-09 21-16-07] txbz_json_UAE_20260709144632.zip"  /sdcard
- 刷新【模拟器】资源管理器: 拷贝文件到【模拟器】后, 需要刷新; 通知Android系统立即扫描指定的文件，并将其信息更新到系统的媒体数据库
  - adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/[2026-07-09 21-16-07] txbz_json_UAE_20260709144632.zip
- 查询【模拟器】文件列表:
  - adb shell ls -l /storage/emulated/0/
  - 【DEBUG】adb shell run-as com.hytera.cpd ls -l /data/user/0/com.hytera.cpd/app_flutter/CPD/uploads
- 重启服务:
  - adb kill-server
  - adb start-server
  
### 路径说明
- 数据库:
  - 【android】路径: 
    - /data/data/com.hytera.cpd/app_flutter/CPD/app_db
    - adb shell run-as com.hytera.cpd ls -l /data/user/0/com.hytera.cpd/app_flutter/CPD/app_db
  - 【win】路径: C:\Users\Administrator\Documents\CPD\app_db
- 远程静态资源:
  - 【android】路径: 
    - /data/data/com.hytera.cpd/app_flutter/CPD/static
    - adb shell run-as com.hytera.cpd ls -l /data/user/0/com.hytera.cpd/app_flutter/CPD/static
  - 【win】路径: C:\Users\Administrator\Documents\CPD\static
  - 【远程】访问地址: localhost:8080/uploads
- 文件上传:【压缩包】的存储及解压
  - 【android】路径: 
    - /data/data/com.hytera.cpd/app_flutter/CPD/uploads
    - adb shell run-as com.hytera.cpd ls -l /data/user/0/com.hytera.cpd/app_flutter/CPD/uploads
  - 【win】路径: C:\Users\Administrator\Documents\CPD\uploads
- 压缩文件夹临时目录: 压缩多个文件后的临时存储目录
  - 【android】路径: 
    - /data/data/com.hytera.cpd/app_flutter/CPD/zipCache
    - adb shell run-as com.hytera.cpd ls -l /data/user/0/com.hytera.cpd/app_flutter/CPD/zipCache
  - 【win】路径: C:\Users\Administrator\Documents\CPD\zipCache
- 其他:
  - 【Device Explorer】路径: /storage/self/primary

- 构建
    - 配置文件：build.yaml
    - 开发环境: flutter pub run build_runner watch
    - 删除文件重新构建：pub run build_runner build --delete-conflicting-outputs

- 国际化 ✅
    - 配置文件：build.yaml
    - 安装
        - fvm flutter pub add slang
        - fvm flutter pub add slang_flutter
        - fvm flutter pub add dev:build_runner
        - fvm flutter pub add dev:slang_build_runner
    - 生成: dart run slang -d
    - 使用
        ```
        final t = Translations.of(context);
        t.common.welcome(appName: 'Slang')
        ```
- 一键修改包名 ✅
    - 安装：fvm flutter pub add dev:change_app_package_name
    - 使用: dart run change_app_package_name:main com.hytera.flutter_kts_templtae

- 日志封装
    - GlobalLogger.logTrace("打印)
    - 💛多参数

- 批量引入阿里巴巴矢量图库 ✅
    - 安装: flutter pub add dev:iconfont_convert
    - 使用: 
      - 修改 iconfig.yaml 的 url 地址
      - dart run iconfont_convert --config iconfont.yaml (执行完命令后，需要重启工程)
      - Icon(HyIcons.xiangzuojiantou)
    - 注意：此插件貌似有问题, 无法在 pubspec.yaml 中自动填入iconfont，可以先手动填写，再执行命令

- 配置文件 ✅
    - 文件名称
        - .env.dev
        - .env.pro
    - 使用: static const String mode = String.fromEnvironment('ENV_MODE', defaultValue: 'test');

- 后端服务封装
    - 路由 ✅
    - 公用返回类：ApiResponse
  
- 前端路由
  - 安装:  fvm flutter pub add go-router
  - 使用:
    - context.go("/home");
    - if(context.canPop()) { context.pop();}

- 数据库访问
    - 安装：
        - 常用
            - flutter pub add objectbox objectbox_flutter_libs:any
            - flutter pub add --dev build_runner objectbox_generator:any
        - 需要访问同步功能
            - flutter pub add objectbox objectbox_sync_flutter_libs:any
            - flutter pub add --dev build_runner objectbox_generator:any
      - 使用
            - 实体类转JSON: flutter pub run build_runner build --delete-conflicting-outputs
            - 通过网页查看数据库: docker run -d --name objectbox-admin -v C:\Users\Administrator\Documents\app_db:/db --publish 8081:8081 objectboxio/admin:latest
            - 指定文件: dart run build_runner build --build-filter="lib/models/user.dart"
            - 注意： 生成的缓存文件在 [lib](.dart_tool/build/generated/flutter_kts_template/lib/core/databaseManager/entities/xx/xxx.info)
      - 如果以上 build_runner 命令出现问题，请使用：
        - dart run build_runner build --delete-conflicting-outputs --verbose
        - 100% 可行：
          - 运行前需要: dart run slang -d
          - flutter pub run build_runner build --delete-conflicting-outputs --force-jit (大概率能解决，使用 jit 方式 跳过预编译、Hook 生成文件)
          
- rename_app: 重命名应用名称
  - dart run rename_app:main all="CPD"
  - dart run rename_app:main android="CPD" ios="CPD" others="CPD"
  - dart run rename_app:main android="CPD_ANDROID" ios="CPD_IOS" web="CPD_WEB" mac="CPD_MAC" windows="CPD_WINDOWS" linux="CPD_LINUX"
  
- reband-cli:  可同时修改APP打包名称、包名、APP图标
  - 配置文件: rebrand_config
  - dart pub global activate rebrand_cli
  - 配置环境变量 PATH 添加一行：D:\work\flutter\template\3-38-10\PUB_CACHE\bin
  - rebrand
  
- TODO:
  - shelf_limiter 
  - shelf_rate_limiter