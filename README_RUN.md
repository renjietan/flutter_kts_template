### 打包:
- 执行
  - windows: .\tool\build_windows.ps1
  - android: .\tool\build_android.ps1
- 安装包存放路径:
  - windows:  
  - android:build/app/outputs/flutter-apk 
### 运行: flutter run -d windwos/android
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
### 调试
- 推送文件到模拟器或真机: 
  - adb devices
  - adb push your_file.txt /sdcard/Download/
  - adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Download/xxx.zip
  - adb shell run-as com.hytera.cpd ls -l /data/user/0/com.hytera.cpd/app_flutter/CPD/uploads
- 设置
  - 平板
    - adb shell wm size 1920x1200
    - adb shell wm density 300
  - 手机
    - adb shell wm size 1080x2340
    - adb shell wm density 480
  - 重置
    - adb shell wm size reset
    - adb shell wm density reset