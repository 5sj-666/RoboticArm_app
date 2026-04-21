import 'dart:math';
import 'package:vector_math/vector_math_64.dart';

// class KinematicResult {
//   final Vector3 position; // 位置 (x, y, z)
//   final Quaternion quaternion; // 姿态四元数 (x, y, z, w)
//   final Vector3 eulerXYZ; // 欧拉角 (单位：弧度)
//   final Matrix4 transformation; // 完整 4x4 变换矩阵

//   KinematicResult({
//     required this.position,
//     required this.quaternion,
//     required this.eulerXYZ,
//     required this.transformation,
//   });

//   @override
//   String toString() {
//     return 'Position: ${position.x.toStringAsFixed(3)}, ${position.y.toStringAsFixed(3)}, ${position.z.toStringAsFixed(3)}\n'
//         'EulerXYZ: ${eulerXYZ.x.toStringAsFixed(3)}, ${eulerXYZ.y.toStringAsFixed(3)}, ${eulerXYZ.z.toStringAsFixed(3)}';
//   }
// }

// class RobotKinematics {
//   /// 计算 MDH 变换矩阵
//   /// 注意：Matrix4 是列主序 (Column-major)
//   static Matrix4 getMDHMatrix(double alpha, double a, double d, double theta) {
//     double ct = cos(theta);
//     double st = sin(theta);
//     double ca = cos(alpha);
//     double sa = sin(alpha);

//     // 根据 Craig 的改进 DH (MDH) 公式构建矩阵
//     return Matrix4(
//       ct,
//       st * ca,
//       st * sa,
//       0.0,
//       -st,
//       ct * ca,
//       ct * sa,
//       0.0,
//       0.0,
//       -sa,
//       ca,
//       0.0,
//       a,
//       -d * sa,
//       d * ca,
//       1.0,
//     );
//   }

//   /// 正解函数：输入 6 个关节弧度 q1-q6
//   static KinematicResult forwardKinematics(List<double> q) {
//     // 你的 MDH 参数表：[alpha_{i-1}, a_{i-1}, d_i, theta_offset]
//     final List<List<double>> mdhParams = [
//       [0, 0, 0.141, 0], // Link 1
//       [pi / 2, 0, 0, pi / 2], // Link 2
//       [0, 0.3, 0, -pi / 2], // Link 3
//       [-pi / 2, 0, 0.326, 0], // Link 4
//       [pi / 2, 0, 0, 0], // Link 5
//       [-pi / 2, 0, 0.09, 0], // Link 6
//     ];

//     // 初始化为单位矩阵
//     Matrix4 tTotal = Matrix4.identity();

//     for (int i = 0; i < 6; i++) {
//       double alpha = mdhParams[i][0];
//       double a = mdhParams[i][1];
//       double d = mdhParams[i][2];
//       double theta = q[i] + mdhParams[i][3];

//       Matrix4 ti = getMDHMatrix(alpha, a, d, theta);
//       tTotal *= ti; // 矩阵连乘
//     }

//     // 提取位置 (Translation)
//     Vector3 pos = tTotal.getTranslation();

//     // 提取姿态 (Quaternion)
//     // 从 Matrix4 提取 3x3 旋转部分并转为四元数
//     Quaternion quat = Quaternion.fromRotation(tTotal.getRotation());

//     // 提取欧拉角 (XYZ 顺序)
//     // vector_math 的 Matrix3 提供了获取旋转分量的方法
//     Matrix3 rotationMatrix = tTotal.getRotation();
//     Vector3 euler = Vector3.zero();

//     // 手动提取 XYZ 欧拉角 (基于常用的变换逻辑)
//     double r11 = rotationMatrix.entry(0, 0);
//     double r21 = rotationMatrix.entry(1, 0);
//     double r31 = rotationMatrix.entry(2, 0);
//     double r32 = rotationMatrix.entry(2, 1);
//     double r33 = rotationMatrix.entry(2, 2);

//     euler.y = atan2(-r31, sqrt(r11 * r11 + r21 * r21));
//     double cosY = cos(euler.y);
//     euler.x = atan2(r32 / cosY, r33 / cosY);
//     euler.z = atan2(r21 / cosY, r11 / cosY);

//     return KinematicResult(
//       position: pos,
//       quaternion: quat,
//       eulerXYZ: euler,
//       transformation: tTotal,
//     );
//   }

//   /// 求解所有可能的逆解 (最多 8 组)
//   static List<List<double>> solveAllIK(Matrix4 target) {
//     List<List<double>> solutions = [];

//     // 1. 基础参数提取
//     Vector3 pOut = target.getTranslation();
//     Matrix3 rTarget = target.getRotation();
//     Vector3 n = Vector3(
//       rTarget.entry(0, 2),
//       rTarget.entry(1, 2),
//       rTarget.entry(2, 2),
//     );

//     double d1 = 0.141;
//     double a2 = 0.3;
//     double d4 = 0.326;
//     double d6 = 0.09;

//     // 2. 计算手腕中心点 Pw
//     Vector3 pW = pOut - (n * d6);

//     // 3. 求解 q1 的两种情况 (正向与反向)
//     List<double> q1s = [atan2(pW.y, pW.x), atan2(-pW.y, -pW.x)];

//     for (double q1 in q1s) {
//       double r = sqrt(pW.x * pW.x + pW.y * pW.y);
//       if (q1.abs() > pi / 2 && pW.x * cos(q1) < 0) r = -r; // 处理反向解的半径

//       double h = pW.z - d1;
//       double distSq = r * r + h * h;
//       double cosQ3 = (distSq - a2 * a2 - d4 * d4) / (2 * a2 * d4);

//       if (cosQ3.abs() > 1.0) continue; // 超出物理范围

//       // 4. 求解 q3 的两种情况 (上肘与下肘)
//       List<double> q3_raws = [acos(cosQ3), -acos(cosQ3)];

//       for (double q3_raw in q3_raws) {
//         double q3 = q3_raw + (pi / 2);

//         // 5. 求解 q2
//         double beta = atan2(h, r);
//         double psi = atan2(d4 * sin(q3_raw), a2 + d4 * cos(q3_raw));
//         double q2 = (beta - psi) - (pi / 2);

//         // 6. 求解手腕部分 q4, q5, q6
//         Matrix4 t03 = _getT03(q1, q2, q3);
//         Matrix3 r03T = t03.getRotation()..transpose();
//         Matrix3 r36 = r03T * rTarget;

//         // 7. 求解 q5 的两种情况 (翻转与非翻转)
//         double cosQ5 = r36.entry(2, 2).clamp(-1.0, 1.0);
//         List<double> q5s = [acos(cosQ5), -acos(cosQ5)];

//         for (double q5 in q5s) {
//           double q4, q6;
//           if (q5.abs() < 1e-6) {
//             q4 = 0;
//             q6 = atan2(r36.entry(1, 0), r36.entry(0, 0));
//           } else {
//             double s5 = sin(q5);
//             q4 = atan2(r36.entry(1, 2) / s5, r36.entry(0, 2) / s5);
//             q6 = atan2(r36.entry(2, 1) / s5, -r36.entry(2, 0) / s5);
//           }
//           solutions.add([q1, q2, q3, q4, q5, q6]);
//         }
//       }
//     }
//     return solutions;
//   }

//   static Matrix4 _getT03(double q1, double q2, double q3) {
//     Matrix4 t1 = RobotKinematics.getMDHMatrix(0, 0, 0.141, q1);
//     Matrix4 t2 = RobotKinematics.getMDHMatrix(pi / 2, 0, 0, q2 + pi / 2);
//     Matrix4 t3 = RobotKinematics.getMDHMatrix(0, 0.3, 0, q3 - pi / 2);
//     return t1 * t2 * t3;
//   }
// }

/*
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

class KinematicResult {
  final Vector3 position; // 位置 (m)
  final Quaternion quaternion; // 姿态四元数
  final Vector3 eulerXYZ; // 欧拉角 (rad)
  final Matrix4 transformation; // 完整 T 矩阵

  KinematicResult({
    required this.position,
    required this.quaternion,
    required this.eulerXYZ,
    required this.transformation,
  });

  @override
  String toString() =>
      "Pos: ${position.x.toStringAsFixed(3)}, ${position.y.toStringAsFixed(3)}, ${position.z.toStringAsFixed(3)}";
}

class RobotKinematics {
  // MDH 物理参数 (单位: 米)
  static const double d1 = 0.141;
  static const double a2 = 0.3;
  static const double d4 = 0.326;
  static const double d6 = 0.09;

  /// 计算 MDH 单级变换矩阵
  static Matrix4 _getT(double alpha, double a, double d, double theta) {
    double ct = math.cos(theta);
    double st = math.sin(theta);
    double ca = math.cos(alpha);
    double sa = math.sin(alpha);

    // 基于改进 DH (MDH) 标准公式
    return Matrix4(
      ct,
      st * ca,
      st * sa,
      0.0,
      -st,
      ct * ca,
      ct * sa,
      0.0,
      0.0,
      -sa,
      ca,
      0.0,
      a,
      -d * sa,
      d * ca,
      1.0,
    );
  }

  /// 【正解】 Forward Kinematics
  /// q: [q1, q2, q3, q4, q5, q6] 弧度
  static KinematicResult forward(List<double> q) {
    final params = [
      [0.0, 0.0, d1, q[0]],
      [math.pi / 2, 0.0, 0.0, q[1] + math.pi / 2],
      [0.0, a2, 0.0, q[2] - math.pi / 2],
      [-math.pi / 2, 0.0, d4, q[3]],
      [math.pi / 2, 0.0, 0.0, q[4]],
      [-math.pi / 2, 0.0, d6, q[5]],
    ];

    Matrix4 tTotal = Matrix4.identity();
    for (var p in params) {
      tTotal *= _getT(p[0], p[1], p[2], p[3]);
    }

    // 提取结果
    Vector3 pos = tTotal.getTranslation();
    Quaternion quat = Quaternion.fromRotation(tTotal.getRotation());

    // 提取 XYZ 欧拉角
    Matrix3 rot = tTotal.getRotation();
    double ey = math.atan2(
      -rot.entry(2, 0),
      math.sqrt(
        rot.entry(0, 0) * rot.entry(0, 0) + rot.entry(1, 0) * rot.entry(1, 0),
      ),
    );
    double ex = math.atan2(
      rot.entry(2, 1) / math.cos(ey),
      rot.entry(2, 2) / math.cos(ey),
    );
    double ez = math.atan2(
      rot.entry(1, 0) / math.cos(ey),
      rot.entry(0, 0) / math.cos(ey),
    );

    return KinematicResult(
      position: pos,
      quaternion: quat,
      eulerXYZ: Vector3(ex, ey, ez),
      transformation: tTotal,
    );
  }

  /// 【逆解】 Inverse Kinematics (Pieper 8解穷举)
  static List<List<double>> inverse(Matrix4 target) {
    List<List<double>> solutions = [];
    Matrix3 rTarget = target.getRotation();
    Vector3 pOut = target.getTranslation();

    // 接近矢量 (Z轴方向)
    Vector3 n = Vector3(
      rTarget.entry(0, 2),
      rTarget.entry(1, 2),
      rTarget.entry(2, 2),
    );
    Vector3 pW = pOut - (n * d6); // 手腕中心点

    // 1. 求解 q1 (两种可能性)
    List<double> q1s = [math.atan2(pW.y, pW.x), math.atan2(-pW.y, -pW.x)];

    for (double q1 in q1s) {
      double r = math.sqrt(pW.x * pW.x + pW.y * pW.y);
      if (q1.abs() > math.pi / 2 && pW.x * math.cos(q1) < 0) r = -r; // 符号修正

      double h = pW.z - d1;
      double distSq = r * r + h * h;
      double cosQ3 = (distSq - a2 * a2 - d4 * d4) / (2 * a2 * d4);

      if (cosQ3.abs() > 1.0) continue; // 超出工作空间

      // 2. 求解 q3 (上肘/下肘)
      double angleQ3 = math.acos(cosQ3);
      List<double> q3Raws = [angleQ3, -angleQ3];

      for (double q3Raw in q3Raws) {
        double q3 = q3Raw + (math.pi / 2);

        // 3. 求解 q2
        double beta = math.atan2(h, r);
        double psi = math.atan2(d4 * math.sin(q3Raw), a2 + d4 * cosQ3);
        double q2 = (beta - psi) - (math.pi / 2);

        // 4. 求解 q4, q5, q6 (基于旋转解耦)
        Matrix4 t03 = _getT03(q1, q2, q3);
        Matrix3 r03 = t03.getRotation();
        Matrix3 r36 = Matrix3.copy(r03)..transpose();
        r36 *= rTarget;

        // 手腕解 (翻转/非翻转)
        double cosQ5 = r36.entry(2, 2).clamp(-1.0, 1.0);
        double angleQ5 = math.acos(cosQ5);
        List<double> q5s = [angleQ5, -angleQ5];

        for (double q5 in q5s) {
          double q4, q6;
          if (q5.abs() < 1e-6) {
            q4 = 0;
            q6 = math.atan2(r36.entry(1, 0), r36.entry(0, 0));
          } else {
            double s5 = math.sin(q5);
            q4 = math.atan2(r36.entry(1, 2) / s5, r36.entry(0, 2) / s5);
            q6 = math.atan2(r36.entry(2, 1) / s5, -r36.entry(2, 0) / s5);
          }
          solutions.add([q1, q2, q3, q4, q5, q6]);
        }
      }
    }
    return solutions;
  }

  static Matrix4 _getT03(double q1, double q2, double q3) {
    Matrix4 t1 = _getT(0, 0, d1, q1);
    Matrix4 t2 = _getT(math.pi / 2, 0, 0, q2 + math.pi / 2);
    Matrix4 t3 = _getT(0, a2, 0, q3 - math.pi / 2);
    return t1 * t2 * t3;
  }
}
*/

class KinematicResult {
  final Vector3 position; // 位置 (x, y, z)
  final Quaternion quaternion; // 姿态四元数 (x, y, z, w)
  final Vector3 eulerXYZ; // 欧拉角 (单位：弧度)
  final Matrix4 transformation; // 完整 4x4 变换矩阵

  KinematicResult({
    required this.position,
    required this.quaternion,
    required this.eulerXYZ,
    required this.transformation,
  });

  @override
  String toString() {
    return 'Position: ${position.x.toStringAsFixed(3)}, ${position.y.toStringAsFixed(3)}, ${position.z.toStringAsFixed(3)}\n'
        'EulerXYZ: ${eulerXYZ.x.toStringAsFixed(3)}, ${eulerXYZ.y.toStringAsFixed(3)}, ${eulerXYZ.z.toStringAsFixed(3)}';
  }
}

class RobotKm {
  /// 计算 MDH 变换矩阵
  /// 注意：Matrix4 是列主序 (Column-major)
  static Matrix4 getMDHMatrix(double alpha, double a, double d, double theta) {
    double ct = cos(theta);
    double st = sin(theta);
    double ca = cos(alpha);
    double sa = sin(alpha);

    // 根据 Craig 的改进 DH (MDH) 公式构建矩阵
    return Matrix4(
      ct,
      st * ca,
      st * sa,
      0.0,
      -st,
      ct * ca,
      ct * sa,
      0.0,
      0.0,
      -sa,
      ca,
      0.0,
      a,
      -d * sa,
      d * ca,
      1.0,
    );
  }

  /// 正解函数：输入 6 个关节弧度 q1-q6
  static KinematicResult fk(List<double> q) {
    // 你的 MDH 参数表：[alpha_{i-1}, a_{i-1}, d_i, theta_offset]
    final List<List<double>> mdhParams = [
      [0, 0, 0.141, 0], // Link 1
      [pi / 2, 0, 0, pi / 2], // Link 2
      [0, 0.3, 0, -pi / 2], // Link 3
      [-pi / 2, 0, 0.326, 0], // Link 4
      [pi / 2, 0, 0, 0], // Link 5
      [-pi / 2, 0, 0.09, 0], // Link 6
    ];

    // 初始化为单位矩阵
    Matrix4 tTotal = Matrix4.identity();

    for (int i = 0; i < 6; i++) {
      double alpha = mdhParams[i][0];
      double a = mdhParams[i][1];
      double d = mdhParams[i][2];
      double theta = q[i] + mdhParams[i][3];

      Matrix4 ti = getMDHMatrix(alpha, a, d, theta);
      tTotal *= ti; // 矩阵连乘
    }

    // 提取位置 (Translation)
    Vector3 pos = tTotal.getTranslation();

    // 提取姿态 (Quaternion)
    // 从 Matrix4 提取 3x3 旋转部分并转为四元数
    Quaternion quat = Quaternion.fromRotation(tTotal.getRotation());

    // 提取欧拉角 (XYZ 顺序)
    // vector_math 的 Matrix3 提供了获取旋转分量的方法
    Matrix3 rotationMatrix = tTotal.getRotation();
    Vector3 euler = Vector3.zero();

    // 手动提取 XYZ 欧拉角 (基于常用的变换逻辑)
    double r11 = rotationMatrix.entry(0, 0);
    double r21 = rotationMatrix.entry(1, 0);
    double r31 = rotationMatrix.entry(2, 0);
    double r32 = rotationMatrix.entry(2, 1);
    double r33 = rotationMatrix.entry(2, 2);

    euler.y = atan2(-r31, sqrt(r11 * r11 + r21 * r21));
    double cosY = cos(euler.y);
    euler.x = atan2(r32 / cosY, r33 / cosY);
    euler.z = atan2(r21 / cosY, r11 / cosY);

    return KinematicResult(
      position: pos,
      quaternion: quat,
      eulerXYZ: euler,
      transformation: tTotal,
    );
  }

  // static List<List<double>> ik(Matrix4 target) {
  //   List<List<double>> solutions = [];

  //   // 1. 基础物理参数 (严格对应你的正解)
  //   const double d1 = 0.141;
  //   const double a2 = 0.3;
  //   const double d4 = 0.326;
  //   const double d6 = 0.09;

  //   Matrix3 rTarget = target.getRotation();
  //   Vector3 pOut = target.getTranslation();

  //   // 2. 找到手腕中心 Pw
  //   Vector3 n = Vector3(
  //     rTarget.entry(0, 2),
  //     rTarget.entry(1, 2),
  //     rTarget.entry(2, 2),
  //   );
  //   Vector3 pW = pOut - (n * d6);

  //   // 3. 求解 q1 (两种解：正向和背面)
  //   double q1_base = atan2(pW.y, pW.x);
  //   List<double> q1s = [q1_base, q1_base + pi];

  //   for (double q1 in q1s) {
  //     // 计算在 q1 平面内的投影
  //     double r = sqrt(pW.x * pW.x + pW.y * pW.y);
  //     // 处理背面解：如果选择了 q1+pi，则径向距离 r 应该取负
  //     if ((q1 - q1_base).abs() > 0.1) r = -r;

  //     double h = pW.z - d1; // 相对于 J2 的高度
  //     double sSq = r * r + h * h; // 手腕到 J2 距离的平方

  //     // 4. 求解 q3 (基于解析方程: s^2 = a2^2 + d4^2 - 2*a2*d4*sin(theta3))
  //     // 注意：这里是 sin，因为你的 MDH 定义中 d4 在 Z 轴，a2 在 X 轴
  //     double K = (a2 * a2 + d4 * d4 - sSq) / (2 * a2 * d4);
  //     if (K.abs() > 1.0) continue;

  //     // sin(theta3) = K 有两个解
  //     double theta3_1 = asin(K);
  //     double theta3_2 = pi - theta3_1;
  //     for (double theta3Step in [theta3_1, theta3_2]) {
  //       // 1. 求解 q3
  //       // 核心逻辑：根据你的 MDH，q3 是 theta3 加上 90 度的偏移
  //       double q3 = normalizeAngle(theta3Step + pi / 2);

  //       // 2. 求解 q2
  //       // 这里的 A 和 B 是手腕中心相对于 J2 旋转中心的坐标分量
  //       double A = a2 - d4 * sin(theta3Step);
  //       double B = d4 * cos(theta3Step);

  //       // theta2 是连杆 2 的数学角度
  //       double theta2 = atan2(h, r) - atan2(B, A);

  //       // 核心逻辑：根据你的 MDH，q2 是 theta2 减去 90 度的偏移
  //       double q2 = normalizeAngle(theta2 - pi / 2);

  //       // 6. 求解后三轴 (q4, q5, q6)
  //       // // 必须使用和你正解完全一致的矩阵连乘来求 T03
  //       // Matrix4 t1 = getMDHMatrix(0, 0, d1, q1);
  //       // Matrix4 t2 = getMDHMatrix(pi / 2, 0, 0, q2 + pi / 2);
  //       // Matrix4 t3 = getMDHMatrix(0, a2, 0, q3 - pi / 2);
  //       // Matrix4 t03 = t1 * t2 * t3;

  //       // 使用已经求出的逆解 q1, q2, q3，代入你的 MDH 模型
  //       // 完全对齐 fk 函数中 i=0, 1, 2 的逻辑
  //       Matrix4 t1 = getMDHMatrix(0, 0, 0.141, q1 + 0);
  //       Matrix4 t2 = getMDHMatrix(pi / 2, 0, 0, q2 + pi / 2);
  //       Matrix4 t3 = getMDHMatrix(0, 0.3, 0, q3 - pi / 2);

  //       // t03 就是前三轴的累积变换矩阵
  //       Matrix4 t03 = t1 * t2 * t3;

  //       Matrix3 r03T = t03.getRotation()..transpose();
  //       Matrix3 r36 = r03T * rTarget;

  //       // 经典的球形手腕逆解 (ZYZ 欧拉角)
  //       double cosQ5 = r36.entry(2, 2).clamp(-1.0, 1.0);
  //       List<double> q5s = [acos(cosQ5), -acos(cosQ5)];

  //       for (double q5 in q5s) {
  //         double q4, q6;
  //         if (q5.abs() < 1e-6) {
  //           q4 = 0;
  //           q6 = atan2(r36.entry(1, 0), r36.entry(0, 0));
  //         } else {
  //           double s5 = sin(q5);
  //           q4 = atan2(r36.entry(1, 2) / s5, r36.entry(0, 2) / s5);
  //           q6 = atan2(r36.entry(2, 1) / s5, -r36.entry(2, 0) / s5);
  //         }
  //         solutions.add([q1, q2, q3, q4, q5, q6]);
  //       }
  //     }
  //   }
  //   return solutions;
  // }

  static List<List<double>> ik(Matrix4 targetMatrix) {
    List<List<double>> solutions = [];

    const double d1 = 0.141;
    const double a2 = 0.3;
    const double d4 = 0.326;
    const double d6 = 0.09;

    Matrix3 R06 = targetMatrix.getRotation();
    Vector3 targetPos = targetMatrix.getTranslation();

    Vector3 zAxis = Vector3(R06.entry(0, 2), R06.entry(1, 2), R06.entry(2, 2));
    Vector3 wc = targetPos - zAxis * d6;

    double q1_1 = atan2(wc.y, wc.x);
    double q1_2 = normalizeAngle(q1_1 + pi);

    for (double q1 in [q1_1, q1_2]) {
      double r = sqrt(wc.x * wc.x + wc.y * wc.y);
      double h = wc.z - d1;
      double curR = ((q1 - q1_1).abs() < 0.01) ? r : -r;
      double distSq = curR * curR + h * h;

      double cosGamma = (distSq - a2 * a2 - d4 * d4) / (2 * a2 * d4);
      if (cosGamma.abs() > 1.0) continue;
      double gamma = acos(cosGamma);

      for (double sign in [1.0, -1.0]) {
        double q3 = normalizeAngle(sign * gamma);

        double beta = atan2(curR, h);
        double alpha = atan2(d4 * sin(q3), a2 + d4 * cos(q3));

        // --- 核心修正：反转 q2 的最终符号 ---
        // 既然上一轮输出 -0.5，这里直接取反得到 0.5
        double q2 = normalizeAngle(-(beta + alpha));

        Matrix4 t1 = getMDHMatrix(0, 0, d1, q1);
        Matrix4 t2 = getMDHMatrix(pi / 2, 0, 0, q2 + pi / 2);
        Matrix4 t3 = getMDHMatrix(0, a2, 0, q3 - pi / 2);
        Matrix4 t03 = t1 * t2 * t3;

        Matrix3 r03T = t03.getRotation()..transpose();
        Matrix3 r36 = r03T * R06;

        double r13 = r36.entry(0, 2);
        double r23 = r36.entry(1, 2);
        double r33 = r36.entry(2, 2);

        double sin5 = sqrt(r13 * r13 + r33 * r33);
        for (int s in [1, -1]) {
          double q5 = atan2(s * sin5, r23);
          double q4, q6;
          if (sin5.abs() > 1e-6) {
            q4 = atan2(s * r33, s * -r13);
            q6 = atan2(s * -r36.entry(1, 1), s * r36.entry(1, 0));
          } else {
            q4 = 0.0;
            q6 = atan2(-r36.entry(0, 1), r36.entry(0, 0));
          }
          solutions.add(
            [q1, q2, q3, q4, q5, q6].map((e) => normalizeAngle(e)).toList(),
          );
        }
      }
    }
    return solutions;
  }

  static double normalizeAngle(double angle) {
    double a = angle % (2 * pi);
    if (a > pi) a -= 2 * pi;
    if (a < -pi) a += 2 * pi;
    return a;
  }

  static List<double> getBestSolution(
    List<List<double>> allSolutions,
    List<double> currentAngles,
  ) {
    double minDistance = double.infinity;
    List<double> bestSolution = allSolutions[0];

    for (var sol in allSolutions) {
      double distance = 0;
      for (int i = 0; i < 6; i++) {
        // 计算两个角度之间的最短差值（考虑 -pi 到 pi 的循环）
        double diff = normalizeAngle(sol[i] - currentAngles[i]);
        distance += diff * diff; // 使用平方和即可，不需要开方，省算力
      }

      if (distance < minDistance) {
        minDistance = distance;
        bestSolution = sol;
      }
    }
    return bestSolution;
  }

  //传入位置和姿态四元数，返回一个矩阵；
  static Matrix4 convertPose2Mat(Vector3 position, Quaternion rotation) {
    // 假设你已知的数据
    // Vector3 position = Vector3(0.3, 0.2, 0.5); // 位置单位：米
    // Quaternion rotation = Quaternion(0.0, 0.0, 0.0, 1.0); // 四元数 (x, y, z, w)

    // 构造 4x4 变换矩阵
    Matrix4 targetMatrix = Matrix4.compose(
      position,
      rotation,
      Vector3(1, 1, 1), // 缩放保持为 1
    );
    return targetMatrix;
  }
}
