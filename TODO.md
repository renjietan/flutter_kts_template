- 不需要 弹窗的 Network Interface
- 未来战士 进行分组


- key 下面文件名称有变化（aes256 => key_aes256）
- key 文件夹名称有变化 (1_resources => 1_key)
- NetNodes 数据格式有变化
  - 旧:
```agsl
  “NetNodes” :[{
    "NodeId": "nn_type2_10009",
    "CodeName": "通信指挥车-04",
    "Users": [
      {
        "UserId": "user_AAA_10001",
        "CodeName": "张三01"
      },
      {
        "UserId": "user_BBB_10002",
        "CodeName": "李四02"
      }
    ]
  }],
```
  - 新:
```agsl
"NetNodes": [
  "nn_vehicle_1001010000"
],
```
- 