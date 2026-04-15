import 'dart:math';

class RobotFK {
  Map<String, dynamic> solve(List<double> angles) {
    if (angles.length != 6) {
      throw ArgumentError("必须输入 6 个关节角度");
    }

    double d2r = pi / 180.0;
    double q1 = angles[0] * d2r;
    double q2 = angles[1] * d2r;
    double q3 = angles[2] * d2r;
    double q4 = angles[3] * d2r;
    double q5 = angles[4] * d2r;
    double q6 = angles[5] * d2r;

    // ✅ 你最终正确的 MDH 参数
    List<List<double>> mdhParams = [
      [0, 0, 0.15, q1],
      [pi / 2, 0, 0.065, q2 + pi / 2],
      [0, 0.3, 0.065, q3 + pi / 2],
      [-pi / 2, 0.035, 0.317, q4],
      [pi / 2, 0, 0, q5],
      [-pi / 2, 0, 0.078, q6],
    ];

    // 级联矩阵计算
    List<double> T = _identity();
    for (var p in mdhParams) {
      T = _multiply(T, _mdhMatrix(p[0], p[1], p[2], p[3]));
    }

    // 位置（正确）
    double x = T[3];
    double y = T[7];
    double z = T[11];

    // 旋转矩阵分量
    double r11 = T[0], r12 = T[1], r13 = T[2];
    double r21 = T[4], r22 = T[5], r23 = T[6];
    double r31 = T[8], r32 = T[9], r33 = T[10];

    // ==============================
    // 正确 RPY（ZYX 顺序，适配你的臂）
    // ==============================
    double roll, pitch, yaw;
    pitch = asin(-r31);
    if (cos(pitch).abs() > 1e-6) {
      roll = atan2(r32, r33);
      yaw = atan2(r21, r11);
    } else {
      roll = 0.0;
      yaw = atan2(-r12, r22);
    }

    // ==============================
    // ✅ RPY 转 四元数 Quaternion
    // ==============================
    Map<String, double> quat = _rpyToQuaternion(roll, pitch, yaw);

    return {
      "position": {"x": x, "y": y, "z": z},
      "orientation": {"roll": roll, "pitch": pitch, "yaw": yaw},
      "quaternion": quat, // 👈 直接用这个给 Three.js
      "matrix": T,
    };
  }

  // ==============================
  // ✅ 核心：RPY -> 四元数
  // ==============================
  Map<String, double> _rpyToQuaternion(double roll, double pitch, double yaw) {
    double cy = cos(yaw * 0.5);
    double sy = sin(yaw * 0.5);
    double cp = cos(pitch * 0.5);
    double sp = sin(pitch * 0.5);
    double cr = cos(roll * 0.5);
    double sr = sin(roll * 0.5);

    double qw = cr * cp * cy + sr * sp * sy;
    double qx = sr * cp * cy - cr * sp * sy;
    double qy = cr * sp * cy + sr * cp * sy;
    double qz = cr * cp * sy - sr * sp * cy;

    return {"x": qx, "y": qy, "z": qz, "w": qw};
  }

  // 标准 MDH 矩阵
  List<double> _mdhMatrix(double alpha, double a, double d, double theta) {
    double ct = cos(theta);
    double st = sin(theta);
    double ca = cos(alpha);
    double sa = sin(alpha);

    return [
      ct,
      -st,
      0,
      a,
      st * ca,
      ct * ca,
      -sa,
      d * sa,
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

  // 矩阵乘法
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
}
// import 'dart:math';

// class RobotFK {
//   Map<String, dynamic> solve(List<double> angles) {
//     if (angles.length != 6) {
//       throw ArgumentError("必须输入 6 个关节角度");
//     }

//     double d2r = pi / 180.0;

//     // 关节角度（直接使用，因为 MDH 里已经包含了 q2-90 偏置）
//     double q1 = angles[0] * d2r;
//     double q2 = angles[1] * d2r;
//     double q3 = angles[2] * d2r;
//     double q4 = angles[3] * d2r;
//     double q5 = angles[4] * d2r;
//     double q6 = angles[5] * d2r;

//     // ✅ 你给的【标准正确 MDH 参数】
//     List<List<double>> mdhParams = [
//       [0, 0, 0.15, q1],
//       [pi / 2, 0, 0.065, q2 + pi / 2], // 这里用弧度 -pi/2 = -90°
//       [0, 0.3, 0.065, q3 + pi / 2],
//       [-pi / 2, 0.035, 0.317, q4],
//       [pi / 2, 0, 0, q5],
//       [-pi / 2, 0, 0.078, q6],
//     ];

//     // 级联变换
//     List<double> T = _identity();
//     for (var p in mdhParams) {
//       T = _multiply(T, _mdhMatrix(p[0], p[1], p[2], p[3]));
//     }

//     // 末端位置
//     double x = T[3];
//     double y = T[7];
//     double z = T[11];

//     // 姿态 RPY（正确旋转顺序）
//     double r11 = T[0], r21 = T[4], r31 = T[8];
//     double r32 = T[9], r33 = T[10];

//     double pitch = atan2(-r31, sqrt(r32 * r32 + r33 * r33));
//     double roll, yaw;

//     if (pitch.abs() > pi / 2 - 0.01) {
//       roll = 0;
//       yaw = atan2(T[6], T[5]);
//     } else {
//       roll = atan2(r32, r33);
//       yaw = atan2(r21, r11);
//     }

//     return {
//       "x": x,
//       "y": y,
//       "z": z,
//       "roll": roll,
//       "pitch": pitch,
//       "yaw": -yaw,
//       "matrix": T,
//     };
//   }

//   // ✅ 标准正确 Modified DH 矩阵
//   List<double> _mdhMatrix(double alpha, double a, double d, double theta) {
//     double ct = cos(theta);
//     double st = sin(theta);
//     double ca = cos(alpha);
//     double sa = sin(alpha);

//     return [
//       ct,
//       -st,
//       0,
//       a,
//       st * ca,
//       ct * ca,
//       -sa,
//       d * sa,
//       st * sa,
//       ct * sa,
//       ca,
//       d * ca,
//       0,
//       0,
//       0,
//       1,
//     ];
//   }

//   // 4x4矩阵乘法
//   List<double> _multiply(List<double> A, List<double> B) {
//     List<double> res = List.filled(16, 0.0);
//     for (int i = 0; i < 4; i++) {
//       for (int j = 0; j < 4; j++) {
//         double sum = 0;
//         for (int k = 0; k < 4; k++) {
//           sum += A[i * 4 + k] * B[k * 4 + j];
//         }
//         res[i * 4 + j] = sum;
//       }
//     }
//     return res;
//   }

//   List<double> _identity() => [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
// }
