import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:robotic_arm_app/utils/motorCmd.dart';

// 未打开蓝牙，已打开蓝牙， 未知蓝牙（ios的未授权状态）， 未扫描， 扫描中， 扫描完成， 未连接，连接中，已连接
enum BleStatus {
  supported,
  notSupported,
  off,
  on,
  unknow,
  scan,
  scaning,
  scaned,
  connecting,
  connected,
  disconnected,
}

class BleState {
  final BleStatus status;
  final bool isBleOn;
  final List<BluetoothDevice> devices;
  final BluetoothDevice? device;
  // final List<BluetoothService> services;
  final List<BluetoothCharacteristic> charList;
  final BluetoothCharacteristic? char;
  // final StreamSubscription? scanResultSubscription;
  final bool isScanning;
  // final StreamSubscription? scanningSubscription;
  final BluetoothCharacteristic? characteristic;

  BleState({
    this.status = BleStatus.unknow,
    this.isBleOn = false,
    this.devices = const [],
    this.device,
    // this.services = const [],
    // char是 characteristic的缩写
    this.charList = const [],
    this.char,
    // this.scanResultSubscription,
    this.isScanning = false,
    // this.scanningSubscription,
    this.characteristic,
  });

  copyWith({
    BleStatus? status,
    int? index,
    bool? isBleOn,
    List<BluetoothDevice>? devices,
    BluetoothDevice? device,
    // List<BluetoothService>? services,
    List<BluetoothCharacteristic>? charList,
    BluetoothCharacteristic? char,
    // StreamSubscription? scanResultSubscription,
    bool? isScanning,
    // StreamSubscription? scanningSubscription,
    BluetoothCharacteristic? characteristic,
  }) {
    return BleState(
      status: status ?? this.status,
      isBleOn: isBleOn ?? this.isBleOn,
      devices: devices ?? this.devices,
      device: device ?? this.device,
      // services: services ?? this.services,
      charList: charList ?? this.charList,
      char: char ?? this.char,
      // scanResultSubscription:
      // scanResultSubscription ?? this.scanResultSubscription,
      isScanning: isScanning ?? this.isScanning,
      // scanningSubscription: scanningSubscription ?? this.scanningSubscription,
      characteristic: characteristic ?? this.characteristic,
    );
  }
}

class BleCubit extends Cubit<BleState> {
  BleCubit() : super(BleState());

  init() async {
    print('初始化蓝牙');
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false);
    // （可选）自定义日志输出
    FlutterBluePlus.logs.listen((String log) {
      // 可将日志发送至任意位置
      print('---打印蓝牙日志: $log');
      // 正则表达式过滤log，获取函数名，<> 表示刚执行, () 表示执行结束
      /// 写个正则表达式，功能是提取函数名，格式为 <functionName> 或 (functionName)
      // RegExp regExp = RegExp(r'[<\(](.*?)[>\)]
      /// 如何使用正则表达式获取字符串中的目标字符串，只想拿到第一个匹配的字符串

      // final FetchFuncName? getFuncName = firstBracketValue(log);
      // print('---打印蓝牙日志: ${getFuncName?.funcName} 阶段: ${getFuncName?.step}');
      // if (getFuncName != null) {
      // if (getFuncName.step == 'start') {
      //   if (getFuncName.funcName == 'startScan') {
      //     emit(state.copyWith(status: BleStatus.scaning));
      //   }
      // else if (getFuncName.funcName == 'stopScan') {
      //   emit(state.copyWith(status: BleStatus.scaned));
      // }
      // } else if (getFuncName.step == 'end') {}
      // }
    });

    await bleSupported();
    await bleAuthorized();

    /// 监听扫描结果
    // var subscription =
    FlutterBluePlus.onScanResults.listen((List<ScanResult> results) {
      print('扫描到 ${results.length} 个设备');
      if (results.isNotEmpty) {
        ScanResult latestResult = results.last; // 获取最新发现的设备
        print(
          '${latestResult.device.remoteId}: 发现设备 "${latestResult.advertisementData.advName}"',
        );

        emit(state.copyWith(devices: results.map((r) => r.device).toList()));

        // 5. 连接设备
        // bleConnect(latestResult.device);
      }
    }, onError: (error) => print('扫描出错: $error'));
    whenBleDisconnect();
  }

  // 2. 判断是否支持蓝牙
  Future<void> bleSupported() async {
    // 判断是否支持蓝牙
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    } else {
      print('---支持蓝牙---');
    }
  }

  // 3. 判断蓝牙是否授权（ios还没授权时的状态为: BluetoothAdapterState.unknown）
  Future<void> bleAuthorized() async {
    // adapterState 初始状态为 unknown，需等待初始化：
    if (await FlutterBluePlus.adapterState.first ==
        BluetoothAdapterState.unknown) {
      emit(state.copyWith(status: BleStatus.unknow));
      await Future.delayed(const Duration(seconds: 1));
    }

    // 2. 监听蓝牙状态变化
    // 注意：iOS 初始状态通常为 BluetoothAdapterState.unknown
    // 注意：若权限不足，状态会停留在 BluetoothAdapterState.unauthorized
    // var bleAdapterState =
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState bleState) {
      print('--蓝牙状态: $bleState ---');

      if (bleState == BluetoothAdapterState.on) {
        // emit(state.copyWith(isBleOn: true, status: BleStatus.on));
        ///直接设置为可扫描状态
        emit(state.copyWith(isBleOn: true, status: BleStatus.scan));
      } else {
        emit(state.copyWith(isBleOn: false, status: BleStatus.off));
        // 向用户展示错误提示等
      }
    });
  }

  Future<void> bleScan() async {
    emit(state.copyWith(status: BleStatus.scaning));
    await FlutterBluePlus.startScan(
      withServices: [Guid("00ff")], // 匹配指定服务 UUID
      withNames: ["ESP"], // 或匹配指定设备名称
      timeout: Duration(seconds: 15), // 扫描超时时间
    );

    Future.delayed(const Duration(seconds: 15), () {
      emit(state.copyWith(status: BleStatus.scaned));
    });
  }

  Future<void> bleStopScan() async {
    await FlutterBluePlus.stopScan();
    emit(state.copyWith(status: BleStatus.scaned));
  }

  Future<bool> bleConnectDevice(BluetoothDevice device) async {
    try {
      emit(state.copyWith(status: BleStatus.connecting, device: device));
      await device.connect(autoConnect: false, license: License.free);
      emit(state.copyWith(status: BleStatus.connected));
      getWriteChracteristic();
      return true;
    } catch (e) {
      print('连接设备失败: $e');
      emit(state.copyWith(status: BleStatus.disconnected, device: null));
      return false;
    }
  }

  /// 获取特征值。特征值编号: 0xff01
  getWriteChracteristic() async {
    BluetoothDevice? device = state.device;
    if (device == null) return;
    List<BluetoothService> services = await device.discoverServices();

    // ignore: avoid_function_literals_in_foreach_calls
    services.forEach((service) async {
      // 处理服务
      // 读取服务下所有支持读取的特征值
      var characteristics = service.characteristics;
      for (BluetoothCharacteristic characteristic in characteristics) {
        // if (characteristic.properties.read) {
        if (characteristic.properties.write) {
          print('---获取到特征值_写');
          // List<int> value = await characteristic.read();
          // print("特征值：$value");
          emit(state.copyWith(characteristic: characteristic));
          await setNotify();
          characteristic.write([1, 2, 3]);
        }
      }
    });
  }

  setNotify() async {
    if (state.characteristic != null) {
      final subscription = state.characteristic!.lastValueStream.listen((
        List<int> value,
      ) {
        print('----接收到来自蓝牙的通知: $value');
        // lastValueStream 触发场景：
        // - 调用 read() 后
        // - 调用 write() 后
        // - 收到通知时
        // - 首次监听时，会重放最后一次的值（便于初始化）
      });

      state.device?.cancelWhenDisconnected(subscription);
      await state.characteristic?.setNotifyValue(true);
    }
  }

  Future<bool> bleDisconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      //直接设置为等待扫描状态
      emit(state.copyWith(status: BleStatus.scan, device: null));
      return true;
    } catch (e) {
      emit(state.copyWith(status: BleStatus.connecting, device: null));
      print('连接设备失败: $e');
      return false;
    }
  }

  /// 断开蓝牙时的回调
  whenBleDisconnect() {
    if (state.device != null) {
      // 1. 监听断开连接事件
      var subscription = state.device?.connectionState.listen((
        BluetoothConnectionState bleState,
      ) async {
        if (bleState == BluetoothConnectionState.disconnected) {
          // 1. 通常可启动定时任务重连，或立即调用 connect() 重连
          // 2. 断开连接后必须重新发现服务！
          print(
            "断开原因：${state.device?.disconnectReason?.code} ${state.device?.disconnectReason?.description}",
          );
        }
      });

      // 2. 断开连接时取消监听
      // delayed: true → 延迟取消，确保能收到 disconnected 事件（仅适用于 connectionState 监听）
      // next: true → 仅取消下一次断开连接的监听（适用于连接前初始化的监听）
      state.device?.cancelWhenDisconnected(
        subscription as StreamSubscription,
        delayed: true,
        next: true,
      );
    }
  }

  Future<bool> turnOn() async {
    // 3. 手动开启蓝牙（仅 Android 支持，iOS 需用户手动开启）
    if (!kIsWeb && Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
      emit(state.copyWith(isBleOn: !state.isBleOn));
      return true;
    } else {
      return false;
    }
  }

  /// 发送消息给单片机，数据格式List.length === 12 ； i是位置，i+1是速度
  /// positions表示直接将六个关节的位置和速度，以len=12的数组发给单片机
  sendMsg(List<double> message) async {
    if (state.characteristic != null) {
      //接受的是double数组，将其转为unit8List
      Float32List floatList = Float32List.fromList(message);
      // 转换为字节数组
      Uint8List byteList = floatList.buffer.asUint8List();
      await state.characteristic!.write(byteList, withoutResponse: false);
      // state.characteristic.
    } else {
      // 无特征值时的错误处理
    }
  }

  /// 通过蓝牙直接发送点击指令
  sendSingleCmd(List<int> cmd) async {
    if (state.characteristic != null) {
      await state.characteristic!.write(cmd, withoutResponse: false);
    }
  }
}

class FetchFuncName {
  final String funcName;
  final String step;
  FetchFuncName({required this.funcName, required this.step});
}

FetchFuncName? firstBracketValue(String s) {
  final re = RegExp(r'<([^>]+)>|\(([^)]+)\)');
  final m = re.firstMatch(s);
  if (m == null) return null;
  // return m.group(1) ?? m.group(2);
  if (m.group(1) != null) {
    // return m.group(1);
    return FetchFuncName(funcName: '${m.group(1)}', step: 'start');
  } else if (m.group(2) != null) {
    return FetchFuncName(funcName: '${m.group(2)}', step: 'end');
  }
  return null;
}
