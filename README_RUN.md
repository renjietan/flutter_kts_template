- 打包:
  - windows: .\tool\build_windows.ps1
  - android: .\tool\build_android.ps1
- 安装包存放路径:
  - windows:  
  - android:build/app/outputs/flutter-apk
- 运行: 
  - --dart-define-from-file
    D:\work\flutter\template\3-38-10\flutter_kts_template\.env.dev
    --dart-entrypoint-args
    --log-level
    --dart-entrypoint-args
    debug
  - --dart-define-from-file
    D:\work\flutter\template\3-38-10\flutter_kts_template\.env.dev
    --a
    --log-level
    --a
    debug
- 推送文件到 模拟器或真机: adb push your_file.txt /sdcard/Download/