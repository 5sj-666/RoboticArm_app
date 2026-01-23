import 'package:flutter/foundation.dart';

/// 电机TWAI指令生成工具库【最终兼容版】
/// ✅ 完全对齐你的JS代码（含numToUint8Array方法）
/// ✅ 适配小米电机Float32+字节反转协议
class MotorCmdGenerator {
  /// TWAI ID 固定4字节，指令核心标识
  List<int> twaiId = List.filled(4, 0);

  /// TWAI 数据载荷 固定8字节
  List<int> twaiData = List.filled(8, 0);

  /// 核心方法：生成指定类型的指令
  /// [type] 指令类型（ setAsZero /enable/disable/jog5/jog0/limit_spd/loc_ref/run_mode）
  /// [params] 指令参数，可选键：motorId/limit_spd/loc_ref/run_mode
  List<int> generateCMD(String type, [Map<String, dynamic> params = const {}]) {
    final Map<String, Function()> strategies = {
      'setAsZero': () {
        final int motorId = params['motorId'] ?? 0;
        twaiId = [0x06, 0x00, 0xfd, motorId];
        twaiData = [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
      },
      'enable': () {
        final int motorId = params['motorId'] ?? 0;
        twaiId = [0x03, 0x00, 0xfd, motorId];
      },
      'disable': () {
        final int motorId = params['motorId'] ?? 0;
        twaiId = [0x04, 0x00, 0xfd, motorId];
      },
      'jog5': () {
        twaiId = [0x12, 0x00, 0xfd, 0x16];
        twaiData = [0x05, 0x70, 0x00, 0x00, 0x07, 0x01, 0x95, 0x54];
      },
      'jog0': () {
        twaiId = [0x12, 0x00, 0xfd, 0x16];
        twaiData = [0x05, 0x70, 0x00, 0x00, 0x07, 0x00, 0x7f, 0xff];
      },
      'limit_spd': () {
        final int motorId = params['motorId'] ?? 0;
        final double limitSpd = params['limit_spd'] ?? 0.0;
        twaiId = [0x12, 0x00, 0xfd, motorId];
        final List<int> spdBytes = numToUint8Array(limitSpd);
        twaiData = [0x17, 0x70, 0x00, 0x00, ...spdBytes];
      },
      'loc_ref': () {
        final int motorId = params['motorId'] ?? 0;
        final double locRef = params['loc_ref'] ?? 0.0;
        twaiId = [0x12, 0x00, 0xfd, motorId];
        final List<int> locBytes = numToUint8Array(locRef);
        twaiData = [0x16, 0x70, 0x00, 0x00, ...locBytes];
      },

      /// 0运控模式 1 位置模式 2 速度模式 3电流模式
      'run_mode': () {
        final int motorId = params['motorId'] ?? 0;
        final int runMode = params['run_mode'] ?? 0;
        twaiId = [0x12, 0x00, 0xfd, motorId];
        twaiData = [0x05, 0x70, 0x00, 0x00, runMode, 0x00, 0x00, 0x00];
      },
    };

    if (strategies.containsKey(type)) {
      strategies[type]!();
    } else {
      twaiId = List.filled(4, 0);
      twaiData = List.filled(8, 0);
    }

    // final cmd = twaiId;
    // cmd.addAll(twaiData);
    // return cmd;
    return [...twaiId, ...twaiData];
  }

  // List<int> getCmd() {
  //   final cmd = twaiId;
  //   cmd.addAll(twaiData);
  //   return cmd;
  // }

  /// ✅ 【核心兼容】与你的JS版numToUnit8Array 1:1一致的实现
  /// 数字 → 32位Float32 → 4字节Uint8数组 → 反转数组 → 返回
  List<int> numToUint8Array(num numValue) {
    final bytes = Uint8List(4);
    final float32View = Float32List.view(bytes.buffer);
    float32View[0] = numValue.toDouble();
    return bytes;
  }
}
