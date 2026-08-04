# RoboticArm_app

机械臂的上位机软件

打开模拟器：open -a simulator。
运行：  
debugger模式：  
 flutter run  
 输入 r ： reload 热重载  
 输入 R : restart 热重启

release模式（安装到本地，七天内可用）：  
 flutter build ios  
 flutter run --release  
 首次安装需在手机的设置 -》 通用 -》vpn与设备管理 中授权信任

添加依赖包：
flutter pub add three_js_helpers

其他：
pod install
pod --version
pod install flutter

auto_route:
https://pub.dev/packages/auto_route
脚本生成路由文件：dart run build_runner build

json序列化
dart pub run build_runner build

API_KEY存在.env文件中，使用flutter_dotenv加载

动作运行的生命周期：
空闲 -> 准备（应用一个动作） -> 准备中 -> 就绪 -> 运行中（<->暂停） -> 结束（准备）
^
｜
下箭头
归零

蓝牙连接步骤：

1. 设置logLevel
2. 查询是否支持蓝牙
3. 判断蓝牙是否授权（ios还没授权时的状态为: BluetoothAdapterState.unknown）
   3.1 未授权需要请求授权
   3.2 异常状态处理，比如断开重连等。
4. 蓝牙打开状态时，可扫描附近设备
5. 连接目标设备
6. 发送数据（调用services的character写入数据writeC）
   6.1 监测notify
7. 断开连接

## Getting Started

This project is a starting point for a roboticArm.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# 运行指令记录：

使能： [3, 0, 253, motorId, 5, 112, 0, 0, 1, 0, 0, 0]

停止： [4, 0, 253, motorId, 5, 112, 0, 0, 1, 0, 0, 0]

位置模式指令:
runmode： [18, 0, 253, motorId, 5, 112, 0, 0, runmode, 0, 0, 0] // 0: 运控模式 1: 位置模式 2: 速度模式 3: 力矩模式

speed： [18, 0, 253, motorId, 23, 112, 0, 0, 63, 128, 0, 0] // 后四位是速度的unit8Array

location： [18, 0, 253, motorId, 22, 112, 0, 0, 63, 128, 0, 0] // 后四位是位置的unit8Array

# 关键帧数据结构更改

目前改为：
{
name: String,
author: String,
description: String,
keyframes: [
{
time: double,
joints: [], // 六个关节位置
bezier: [], // 控制点1和控制点2
markerTimeStart: double,
markerTimeEnd: double,
},
...
]
}

3d路径编辑：
https://github.com/mrdoob/three.js/blob/master/examples/webgl_geometry_spline_editor.html


toast插件使用:
https://pub.dev/packages/toastification
<!-- https://github.com/nslogx/flutter_easyloading/blob/develop/README-zh_CN.md-->