import 'package:flutter/foundation.dart';

// class parseCmdObj {
//   final int masterId;
//   final int motorId;
//   final List<String> errorArr;
//   final String motorMode;
//   final double locRefNum;
//   final double limitSpdNum;
//   final double torqueNum;
//   final double tempNum;
//   final List<int> rawCmd;
//   final String parseStr;

//   parseCmdObj({
//     required this.masterId,
//     required this.motorId,
//     required this.errorArr,
//     required this.motorMode,
//     required this.locRefNum,
//     required this.limitSpdNum,
//     required this.torqueNum,
//     required this.tempNum,
//     required this.rawCmd,
//     required this.parseStr,
//   });
// }

/// 解析电机指令核心方法
/// [cmd] 指令数组，格式示例：[2,80,16,fd,8d,f1,80,3b,80,76,00,f6]，固定12字节
/// 返回值：Map | null，结构与JS原版完全一致
Map<String, dynamic>? parseCmd(List<int> cmd) {
  print("--parse_cmd: $cmd");

  // 指令合法性校验：非空 + 固定12字节长度
  if (cmd.isEmpty || cmd.length != 12) {
    print('指令错误');
    return null;
  }

  final List<int> identify = cmd.sublist(0, 4);
  final List<int> data = cmd.sublist(4, 12);

  final Map<String, dynamic> headerObj = handleFrameHead(cmd);

  // 指令解析策略映射表
  final Map<int, Map<String, dynamic> Function(List<int>, Map<String, dynamic>)>
  strategy = {0: msg0, 3: msg3, 4: msg4, 18: msg18};

  // 匹配策略执行对应解析逻辑
  if (strategy.containsKey(headerObj['type'])) {
    return strategy[headerObj['type']]!(cmd, headerObj);
  }

  // 回馈帧解析（帧头首字节为2）
  if (identify[0] == 2) {
    final List<String> identifier = identify
        .map((hex) => hex2bit(hex))
        .expand((e) => e)
        .toList();

    // 解析主机ID、电机ID
    final int masterId = int.parse(identifier.sublist(24, 32).join(), radix: 2);
    final int motorId = int.parse(identifier.sublist(16, 24).join(), radix: 2);

    // 故障信息映射与解析
    final Map<int, String> errObj = {
      21: '未标定',
      20: 'HALL编码故障',
      19: '磁编码故障',
      18: '过温',
      17: '过流',
      16: '欠压故障',
    };
    final List<String> errorArr = [];
    final List<String> errBits = identifier.sublist(10, 16);
    for (int i = 0; i < errBits.length; i++) {
      if (errBits[i] == "1") errorArr.add(errObj[21 - i]!);
    }

    // 电机运行模式解析
    final Map<int, String> modeObj = {
      0: 'Reset模式[复位]',
      1: 'Cali 模式[标定]',
      2: 'Motor模式[运行]',
    };
    final String modeBit = identifier.sublist(8, 10).join();
    final String motorMode = modeObj[int.parse(modeBit, radix: 2)]!;

    // 解析帧内容：角度、角速度、扭矩、温度（公式与JS完全一致）
    final List<int> locRef = data.sublist(0, 2);
    final double locRefNum =
        ((locRef[0] << 8 | locRef[1]) - 32767) / 8192 * 180;

    final List<int> limitSpd = data.sublist(2, 4);
    final double limitSpdNum =
        ((limitSpd[0] << 8 | limitSpd[1]) / 65535 * 60) - 30;

    final List<int> torque = data.sublist(4, 6);
    final double torqueNum = ((torque[0] << 8 | torque[1]) / 65535 * 24) - 12;

    final List<int> temp = data.sublist(6, 8);
    final double tempNum = (temp[0] << 8 | temp[1]) / 10;

    // 格式化解析结果文本
    final String errorStr = errorArr.isNotEmpty ? errorArr.join(',') : '无';
    final String parseStr =
        "电机id: $motorId, 错误: $errorStr, 电机模式: $motorMode, "
        "当前角度: $locRefNum°, 角速度: ${(limitSpdNum * 100).toInt() / 100}rad/s, "
        "扭矩: ${(torqueNum * 100).toInt() / 100}Nm, 温度: $tempNum";

    return {
      'masterId': masterId,
      'motorId': motorId,
      'errorArr': errorArr,
      'motorMode': motorMode,
      'loc_ref_num': locRefNum,
      'limit_spd_num': limitSpdNum,
      'torque_num': torqueNum,
      'temp_num': tempNum,
      'rawCmd': cmd,
      'parseStr': parseStr,
    };
  }

  return null;
}

/// 帧头处理方法：拆分bit28~24/bit23~8/bit7~0，返回结构化数据
Map<String, dynamic> handleFrameHead(List<int> cmd) {
  final List<int> identify = cmd.sublist(0, 4);
  final List<String> identifier = identify
      .map((hex) => hex2bit(hex))
      .expand((e) => e)
      .toList();

  final String bit28_24 = identifier.sublist(3, 8).join();
  final String bit23_8 = identifier.sublist(8, 24).join();
  final String bit7_0 = identifier.sublist(24, 32).join();

  return {
    'type': int.parse(bit28_24, radix: 2),
    'bit28_24': bit28_24,
    'bit23_8': bit23_8,
    'bit7_0': bit7_0,
  };
}

/// 16进制转8位二进制数组，不足8位自动补0（对齐JS padStart(8,'0')）
List<String> hex2bit(int hex) {
  String binaryStr = hex.toRadixString(2);
  if (binaryStr.length < 8) binaryStr = binaryStr.padLeft(8, '0');
  return binaryStr.split('');
}

/// 通信类型0：获取设备ID + MCU唯一标识符解析
Map<String, dynamic> msg0(List<int> cmd, Map<String, dynamic> headerObj) {
  final int bit70Val = int.parse(headerObj['bit7_0'], radix: 2);
  // 应答帧
  if (bit70Val == 0xFE) {
    final int canId = int.parse(headerObj['bit23_8'], radix: 2);
    final List<int> mcuId = cmd.sublist(4, 12);
    return {
      'canId': canId,
      'masterId': 0xFE,
      'MCUId': mcuId,
      'rawCmd': cmd,
      'parseStr': "获取到$canId设备ID: ${mcuId.join('')}",
    };
  } else {
    // 请求帧
    final int canId = int.parse(headerObj['bit7_0'], radix: 2);
    final int masterId = int.parse(headerObj['bit23_8'], radix: 2);
    return {
      'canId': canId,
      'masterId': masterId,
      'rawCmd': cmd,
      'parseStr': "请求获取$canId电机的设备ID",
    };
  }
}

/// 通信类型3：电机使能指令解析
Map<String, dynamic> msg3(List<int> cmd, Map<String, dynamic> headerObj) {
  final int canId = int.parse(headerObj['bit7_0'], radix: 2);
  final int masterId = int.parse(headerObj['bit23_8'], radix: 2);
  return {
    'canId': canId,
    'masterId': masterId,
    'rawCmd': cmd,
    'parseStr': "③使能$canId电机",
  };
}

/// 通信类型4：电机停止指令解析
Map<String, dynamic> msg4(List<int> cmd, Map<String, dynamic> headerObj) {
  print("--------电机停止---------");
  final int canId = int.parse(headerObj['bit7_0'], radix: 2);
  final int masterId = int.parse(headerObj['bit23_8'], radix: 2);
  return {
    'canId': canId,
    'masterId': masterId,
    'rawCmd': cmd,
    'parseStr': "④停止$canId电机",
  };
}

/// 通信类型18：单个参数写入指令解析（位置/速度/运行模式）
Map<String, dynamic> msg18(List<int> cmd, Map<String, dynamic> headerObj) {
  print("-------- 单个参数写入(通信类型18) （掉电丢失）---------");
  final int canId = int.parse(headerObj['bit7_0'], radix: 2);
  final int masterId = int.parse(headerObj['bit23_8'], radix: 2);
  final List<int> cmdData = cmd.sublist(4, 12);

  // 解析写入类型（0x7005/0x7016/0x7017）
  final int writeType = (cmdData[1] << 8) | cmdData[0];
  String parseStr = "①⑧写入$canId电机参数";

  // 运行模式解析 0X7005
  if (writeType == 0x7005) {
    final int runMode = cmdData[4];
    final Map<int, String> runModeObj = {
      0: '运控模式',
      1: '位置模式',
      2: '速度模式',
      3: '电流模式',
    };
    parseStr = "①⑧更改$canId电机的run_mode为${runModeObj[runMode] ?? runMode}";
  }

  // 位置模式角度解析 0X7016
  if (writeType == 0x7016) {
    final List<int> locRef = cmdData.sublist(4, 8).reversed.toList();
    final double angle =
        convert32BitFloatTo64BitNumber(locRef) / 3.1415926 * 180;
    parseStr = "①⑧更改$canId电机的位置模式角度为$angle°";
  }

  // 速度限制解析 0X7017
  if (writeType == 0x7017) {
    final List<int> limitSpd = cmdData.sublist(4, 8).reversed.toList();
    final double speed = convert32BitFloatTo64BitNumber(limitSpd);
    parseStr = "①⑧更改$canId电机的位置模式速度限制为$speed";
  }

  return {
    'canId': canId,
    'masterId': masterId,
    'rawCmd': cmd,
    'parseStr': parseStr,
  };
}

/// 将32位浮点数的4字节二进制数据，转换为Dart的64位浮点数(double)
/// [binaryData] 4字节Uint8数组，示例：[0x41, 0x48, 0xF5, 0xC3]
/// 返回值：64位浮点数(double)，与JS Number类型完全一致
double convert32BitFloatTo64BitNumber(List<int> binaryData) {
  // 创建4字节二进制缓冲区
  final Uint8List buffer = Uint8List(4);
  // 循环写入二进制数据
  for (int i = 0; i < 4; i++) {
    buffer[i] = binaryData[i];
  }
  // 读取32位单精度浮点数，并自动转为64位浮点数
  final Float32List float32View = Float32List.view(buffer.buffer);
  return float32View[0].toDouble();
}
