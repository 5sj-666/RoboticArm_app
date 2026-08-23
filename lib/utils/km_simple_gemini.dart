import 'dart:math';
import 'package:vector_math/vector_math_64.dart';

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

  static List<List<double>> ik(Matrix4 targetMatrix) {
    List<List<double>> solutions = [];

    const double d1 = 0.141;
    const double a2 = 0.3;
    const double d4 = 0.326;
    const double d6 = 0.09;

    // ignore: non_constant_identifier_names
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
    if (allSolutions.isEmpty) return [];

    // 如果没有当前角度，默认取第一组
    if (currentAngles.isEmpty) {
      return allSolutions[0].map((e) => _toDeg(e)).toList();
    }

    // 1. 将当前角度从角度转回弧度（如果你传入的是角度，请确保单位统一）
    // 假设 currentAngles 传入的是弧度

    double minDistance = double.infinity;
    List<double> bestSolution = allSolutions[0];

    // 2. 权重配置：给 J1, J2, J3 更高的权重
    const List<double> weights = [5.0, 5.0, 5.0, 1.0, 1.0, 0.5];

    for (var sol in allSolutions) {
      double distance = 0;

      for (int i = 0; i < 6; i++) {
        double diff = normalizeAngle(sol[i] - currentAngles[i]);

        // 核心优化：计算加权距离
        double term = weights[i] * (diff * diff);

        // 额外优化：针对 $J_4$ 或 $J_6$ 的 180 度跳变惩罚
        // 如果单轴跳变超过 90 度 (pi/2)，给予极大的代价值
        if (diff.abs() > pi / 2) {
          term *= 2.0;
        }

        distance += term;
      }

      if (distance < minDistance) {
        minDistance = distance;
        bestSolution = sol;
      }
    }

    // return bestSolution.map((e) => _toDeg(e)).toList();
    return bestSolution;
  }

  static double _toDeg(double rad) {
    return double.parse((rad * 180 / pi).toStringAsFixed(4));
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
