import 'dart:math';

class RobotFK {
  /// 计算正向运动学
  /// [angles] : 6个关节的角度列表 (单位: 度)
  /*Map<String, dynamic> solve(List<double> angles) {
    if (angles.length < 6) throw "需要6个关节角度";

    // 1. 角度转弧度，并应用“竖直零位”偏置
    // 如果你的电机方向相反，请尝试改变 90 的正负号
    double q1 = angles[0] * pi / 180;
    double q2 = (angles[1] + 90) * pi / 180; // 补偿：使大臂竖起
    double q3 = (angles[2] - 90) * pi / 180; // 补偿：使小臂与大臂直线对齐
    double q4 = angles[3] * pi / 180;
    double q5 = angles[4] * pi / 180;
    double q6 = angles[5] * pi / 180;

    // 2. 定义 MDH 参数表 [alpha_{i-1}, a_{i-1}, d_i, theta_i]
    List<List<double>> mdhParams = [
      [0, 0, 0, q1],
      [pi / 2, 0, -0.07, q2],
      [0, 0.3, 0.07, q3],
      [-pi / 2, 0, 0.316, q4],
      [pi / 2, 0, 0, q5],
      [-pi / 2, 0, 0, q6],
    ];

    // 3. 级联计算总变换矩阵
    List<double> currentT = _identity();
    for (var param in mdhParams) {
      List<double> nextT = _getMDHMatrix(
        param[0],
        param[1],
        param[2],
        param[3],
      );
      currentT = _multiply(currentT, nextT);
    }
    var result = {
      "x": _fixPrecision(currentT[3]),
      "y": _fixPrecision(currentT[7]),
      "z": _fixPrecision(currentT[11]),
      "matrix": currentT, // 完整的 4x4 矩阵
    };

    // 4. 提取结果
    return result;
  }
*/
  Map<String, dynamic> solve(List<double> angles) {
    if (angles.length < 6) throw "需要6个关节角度";

    // 1. 角度转弧度 + 零位偏置
    double d2r = pi / 180.0;
    double q1 = angles[0] * d2r;
    double q2 = (angles[1] + 90) * d2r;
    double q3 = (angles[2] - 90) * d2r;
    double q4 = angles[3] * d2r;
    double q5 = angles[4] * d2r;
    double q6 = angles[5] * d2r;

    // 2. MDH 参数级联计算 (逻辑同上)
    List<List<double>> mdhParams = [
      [0, 0, 0.14, q1],
      [pi / 2, 0, -0.07, q2],
      [0, 0.3, 0.07, q3],
      [-pi / 2, 0, 0.316, q4],
      [pi / 2, 0, 0, q5],
      [-pi / 2, 0, 0.06, q6],
    ];

    List<double> T = _identity();
    for (var p in mdhParams) {
      T = _multiply(T, _getMDHMatrix(p[0], p[1], p[2], p[3]));
    }

    // 3. 提取位置
    double x = T[3];
    double y = T[7];
    double z = T[11];

    // 4. 提取姿态 (RPY)
    // 对应矩阵索引: r31 = T[8], r32 = T[9], r33 = T[10], r21 = T[4], r11 = T[0]
    double pitch = atan2(-T[8], sqrt(T[9] * T[9] + T[10] * T[10]));
    double roll, yaw;

    // 检查万向节死锁 (当 pitch 为 ±90° 时)
    if ((pitch - pi / 2).abs() < 0.001) {
      roll = 0;
      yaw = atan2(T[1], T[5]);
    } else if ((pitch + pi / 2).abs() < 0.001) {
      roll = 0;
      yaw = -atan2(T[1], T[5]);
    } else {
      roll = atan2(T[9], T[10]);
      yaw = atan2(T[4], T[0]);
    }

    return {
      "position": {
        "x": _fixPrecision(x),
        "y": _fixPrecision(y),
        "z": _fixPrecision(z),
      },
      "orientation": {
        "roll": _fixPrecision(roll),
        "pitch": _fixPrecision(pitch),
        "yaw": _fixPrecision(yaw),
      },
    };
  }

  /// 构建 MDH 变换矩阵 (4x4 平铺列表)
  List<double> _getMDHMatrix(double alpha, double a, double d, double theta) {
    double ct = cos(theta);
    double st = sin(theta);
    double ca = cos(alpha);
    double sa = sin(alpha);

    // 严格按照 MDH 标准矩阵填充
    return [
      ct,
      -st,
      0,
      a,
      st * ca,
      ct * ca,
      -sa,
      -d * sa,
      st * sa,
      ct * sa,
      ca,
      d * ca,
      0,
      0,
      0,
      1,
    ];
  }

  /// 矩阵乘法 A * B
  List<double> _multiply(List<double> A, List<double> B) {
    List<double> res = List.filled(16, 0.0);
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        double sum = 0;
        for (int k = 0; k < 4; k++) {
          sum += A[i * 4 + k] * B[k * 4 + j];
        }
        res[i * 4 + j] = sum;
      }
    }
    return res;
  }

  List<double> _identity() => [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];

  double _fixPrecision(double v) =>
      (v * 10000).roundToDouble() / 10000; // 保留4位小数
}

// void main() {
//   final fk = RobotFK();

//   // 验证：当所有角度为 0 时（竖直姿态）
//   // 理论上 Z 应该等于 a2 + d4 = 0.3 + 0.316 = 0.616
//   var result = fk.solve([0, 0, 0, 0, 0, 0]);

//   print("--- 零位验证 (应为竖直状态) ---");
//   print("X: ${result['x']}, Y: ${result['y']}, Z: ${result['z']}");
//   // 预期输出接近 X: 0, Y: 0, Z: 0.616
// }
