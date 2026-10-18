/// 从《机器人学导论》书上学到的知识进行函数实现验证
/// MDH坐标系建立
/// 正运动学
/// 逆运动学
/// 雅可比矩阵
/// 动力学建模
///
import 'dart:math';
// import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class KinematicResult {
  final Vector3 position; // 位置 (x, y, z)
  final Quaternion quaternion; // 姿态四元数 (x, y, z, w)
  final Matrix4 transformation; // 完整 4x4 变换矩阵

  KinematicResult({
    required this.position,
    required this.quaternion,
    // required this.eulerXYZ,
    required this.transformation,
  });

  @override
  String toString() {
    return 'Position: ${position.x.toStringAsFixed(3)}, ${position.y.toStringAsFixed(3)}, ${position.z.toStringAsFixed(3)}\n'
        'quaternion:  ${quaternion.x.toStringAsFixed(3)}, ${quaternion.y.toStringAsFixed(3)}, ${quaternion.z.toStringAsFixed(3)}, ${quaternion.w.toStringAsFixed(3)} \n';
  }
}

double d1 = 0.107; //0.0;
double a2 = 0.3; //0.0;
double d4 = 0.32315; //0.0;
double d6 = 0.085; //0.0;

class LinkData {
  double alph;
  double a;
  double d;
  double theta;

  LinkData(this.alph, this.a, this.d, this.theta);
}

class KmPieperUser {
  /// 初始化时，角度都为0
  static List<LinkData> mdh = [
    LinkData(0, 0, d1, 0),
    LinkData(pi / 2, 0, 0, 0),
    LinkData(0, a2, 0, 0),
    LinkData(-pi / 2, 0, d4, 0),
    LinkData(pi / 2, 0, 0, 0),
    LinkData(-pi / 2, 0, d6, 0),
  ];

  // static Matrix3 trans_ZYZ = Matrix3();

  /// 正运动学
  static KinematicResult fk(List<double> jointAnglesDeg) {
    List<double> _jointAnglesDeg = List.from(jointAnglesDeg);
    _jointAnglesDeg[1] = _jointAnglesDeg[1] + 90;
    _jointAnglesDeg[2] = _jointAnglesDeg[2] - 90;

    Matrix4 t1, t2, t3, t4, t5, t6;

    t1 = getT(mdh[0], customTheta: _jointAnglesDeg[0] / 180 * pi);
    t2 = getT(mdh[1], customTheta: _jointAnglesDeg[1] / 180 * pi);
    t3 = getT(mdh[2], customTheta: _jointAnglesDeg[2] / 180 * pi);
    t4 = getT(mdh[3], customTheta: _jointAnglesDeg[3] / 180 * pi);
    t5 = getT(mdh[4], customTheta: _jointAnglesDeg[4] / 180 * pi);
    t6 = getT(mdh[5], customTheta: _jointAnglesDeg[5] / 180 * pi);

    /// 将矩阵连乘，得到坐标6 -> 坐标0 的转换
    Matrix4 t06 = t1 * t2 * t3 * t4 * t5 * t6;

    return KinematicResult(
      // 位置 矩阵最后一列的值
      position: t06.getTranslation(),
      // 姿态3x3矩阵
      quaternion: Quaternion.fromRotation(t06.getRotation()),
      transformation: t06,
    );
  }

  /// 逆运动学
  /// 参数： Matrix4 齐次变换矩阵
  static List<List<double>> ik(Matrix4 pose, List<double>? preJointRad) {
    List<List<double>> solutions = [];

    /// 获取腕部中心位置
    Matrix4 t6_5 = getT(mdh[5])..invert();
    Vector3 wp = (pose * t6_5).getTranslation();

    print("腕部中心: $wp ");

    // double px = pose.entry(0, 3);
    // double py = pose.entry(1, 3);
    // double pz = pose.entry(2, 3);

    // double r13_1 = pose.entry(0, 2);
    // double r23_1 = pose.entry(1, 2);
    // double r33_1 = pose.entry(2, 2);

    // double wx1 = px - d6 * r13_1;
    // double wy1 = py - d6 * r23_1;
    // double wz1 = pz - d6 * r33_1;

    // // wp = Vector3(wx1, wy1, wz1);

    // print("腕部中心1: $wx1 $wy1 $wz1");

    /// 求解theta2和3时，三维坐标需要坍缩成二维坐标，那么底面的长度即为 x的平方 + y的平方 取根号
    /// 变量取名为2维平面的x值
    double y = wp.z - d1;
    // ignore: non_constant_identifier_names
    double x = sqrt(wp.x * wp.x + wp.y * wp.y);

    // 二连杆的长度
    // double l1 = a2;
    // double l2 = d4;

    /// 几何法求解：
    /// 解的个数： a1 = a3 = a5 = 0, 解的个数<=4；
    double th1Base = atan2(wp.y, wp.x);
    List<double> th1List = [th1Base, th1Base + pi];

    for (int i = 0; i < th1List.length; i++) {
      // List<List<double>> blowTheta = [];

      // 当 theta1 加上 pi 时，对应反向构型，径向距离等效取负号
      if (i == 1) {
        x = -x;
      }
      double th1 = th1List[i];

      double sinTh3 = (a2 * a2 + d4 * d4 - (x * x + y * y)) / (2 * a2 * d4);
      // 数学钳位与物理越界拦截
      if (sinTh3 > 1.0) {
        if (sinTh3 > 1.001) continue; // 超出最大物理臂展过多，直接抛弃该解
        sinTh3 = 1.0; // 浮点误差导致的边界奇异点，强制钳位，防止后续 acos 出现 NaN
      } else if (sinTh3 < -1.0) {
        if (sinTh3 < -1.001) continue; // 进入内侧极限折叠死区，抛弃该解
        sinTh3 = -1.0; // 强制钳位
      }
      // --- 分支 2：肘部姿态 (2种: 肘朝上 / 肘朝下) ---
      double cosTh3Base = sqrt(1 - sinTh3 * sinTh3);
      List<double> cosTh3List = [cosTh3Base, -cosTh3Base];
      for (double cosTh3 in cosTh3List) {
        double th3 = atan2(sinTh3, cosTh3);

        double A = a2 - d4 * sinTh3;
        double B = d4 * cosTh3;
        double th2 = atan2(A * y - B * x, A * x + B * y);

        /// 解算姿态 前三轴角度的姿态
        /// 获取后三轴的变换矩阵
        Matrix4 t1 = getT(mdh[0], customTheta: th1);
        Matrix4 t2 = getT(mdh[1], customTheta: th2);
        Matrix4 t3 = getT(mdh[2], customTheta: th3);
        Matrix4 r03 = t1 * t2 * t3;
        // ignore: non_constant_identifier_names
        Matrix4 r03_inv = r03.clone()..invert();
        Matrix4 r36 = r03_inv * pose;

        /// 检查r36矩阵
        print("r36: ${r36.getRotation()}");

        // Matrix4 t4 = getT(mdh[3], customTheta: 40 * pi / 180);
        // Matrix4 t5 = getT(mdh[4], customTheta: 50 * pi / 180);
        // Matrix4 t6 = getT(mdh[5], customTheta: 60 * pi / 180);
        // Matrix4 r36 = t4 * t5 * t6;
        // print("r36T: ${r36T.getRotation()}");

        /// ZYZ欧拉角求解姿态， 《机器人学导论》第31页. 由于有连杆扭转角的存在，所以取值位置需要计算
        // double r13 = r36T.entry(0, 2);
        // double r23 = r36T.entry(1, 2);
        // double r31 = r36T.entry(2, 0);
        // double r32 = r36T.entry(2, 1);
        // double r33 = r36T.entry(2, 2);

        /// r36的第二行第三列是cos(th5)的值
        double r36_12 = r36.entry(1, 2).clamp(-1.0, 1.0);

        double th5Base = acos(r36_12);
        List<double> th5List = [th5Base, -th5Base];
        print("--th5List: ${th5List[0] * 180 / pi} . ${th5List[1] * 180 / pi}");
        for (double th5 in th5List) {
          double th4, th6;
          double sinTh5 = sin(th5);

          if (sinTh5.abs() > 1e-4) {
            // 正常姿态：使用 Dart 的 .sign 属性来获取正负符号 (1.0 或 -1.0)
            double sign = sinTh5.sign;
            th4 = atan2(r36.entry(2, 2) * sign, -r36.entry(0, 2) * sign);
            th6 = atan2(-r36.entry(1, 1) * sign, r36.entry(1, 0) * sign);
          } else {
            // 奇异姿态 (Gimbal Lock)(第五轴角度为0时)：4轴和6轴重合
            if (preJointRad != null && preJointRad.length >= 6) {
              th4 = preJointRad[3]; // 核心：锁定 4轴 为上一帧的角度
              th6 =
                  atan2(-r36.entry(0, 1), r36.entry(0, 0)) -
                  th4; // 让 6轴 承担所有剩余的旋转补偿
            } else {
              th4 = 0.0;
              th6 = atan2(-r36.entry(0, 1), r36.entry(0, 0));
            }
          }

          solutions.add([th1, th2 - pi / 2, th3 + pi / 2, th4, th5, th6]);
        }
      }
    }

    return solutions;
  }

  /// 推导出来的变换矩阵，推导过程在《机器人学导论》第三章. i 到i-1的变换公式
  /// Rx(alph-1)Dx(a)Rz(theta)Dz(d)
  static Matrix4 getT(LinkData linkData, {double? customTheta}) {
    final LinkData(alph: alph, a: a, d: d) = linkData;
    double theta = customTheta ?? linkData.theta;

    // dart format off
    Matrix4 t = Matrix4.identity();
    t.setRow(0, Vector4(cos(theta), -sin(theta), 0, a));
    t.setRow(1, Vector4(sin(theta) * cos(alph), cos(theta) * cos(alph), -sin(alph), -sin(alph) * d));
    t.setRow(2, Vector4(sin(theta) * sin(alph), cos(theta) * sin(alph), cos(alph), cos(alph) * d));
    t.setRow(3, Vector4(0, 0, 0, 1));
    // dart format on
    return t;
  }

  /// 获取最优解
  /// 输入 allSolutions: Array<rad(弧度)> , currentAngles: Array<deg(角度)>
  /// 输出 欧氏距离最近的那一组解：result： Array<deg>
  static List<double> getBestSolution(
    List<List<double>> allSolsRad,
    List<double> curRad,
  ) {
    if (allSolsRad.isEmpty) return [];

    // 如果没有当前角度，默认取第一组
    if (curRad.isEmpty) {
      // return allSolsRad[0].map((e) => _toDeg(e)).toList();
      return allSolsRad[0];
    }

    // 1. 将当前角度从角度转回弧度（如果你传入的是角度，请确保单位统一）
    // 假设 currentAngles 传入的是弧度

    double minDistance = double.infinity;
    List<double> bestSolution = allSolsRad[0];

    // 2. 权重配置：给 J1, J2, J3 更高的权重
    const List<double> weights = [5.0, 5.0, 5.0, 1.0, 1.0, 0.5];

    for (var sol in allSolsRad) {
      double distance = 0;

      for (int i = 0; i < 6; i++) {
        double diff = normalizeAngle(sol[i] - curRad[i]);

        // 核心优化：计算加权距离
        double term = weights[i] * (diff * diff);

        // 如果单轴跳变超过 90 度 (pi/2)，给予极大的代价值
        if (diff.abs() >= pi / 2) {
          term *= 4.0;
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

  /// 检测当前关节状态（弧度）是否处于三大奇异点之一
  bool checkSingularity(List<double> jointsRad) {
    if (jointsRad.length < 6) return false;

    double th2 = jointsRad[1];
    double th3 = jointsRad[2];
    double th5 = jointsRad[4];

    // 1. 腕部奇异点: th5 接近 0 或 $\pi$
    // 4 轴与 6 轴轴线平行或重合，手腕失去旋转自由度。
    // 所以需要锁定其中一个轴
    //   方法1：固定锁轴4或轴6
    //   方法2: 依据上一帧关节数据锁轴4或轴6 （目前尝试锁轴4）
    //   方法3: 依据上一帧和下一帧的关节数据，计算平均值，锁其中一个轴 （最难）
    bool wristSingular = sin(th5).abs() < 1e-3;

    // 2. 肘部奇异点: 连杆伸直或极限折叠 (th3 对应的几何正弦/余弦极限)
    // 可达空间的问题，如果处于在可达空间之外，和大臂小臂的长度差所组成的无法触及的内部空间
    bool elbowSingular = cos(th3).abs() < 1e-3;

    // 3. 肩部奇异点: 腕心落在基座 Z0 轴上
    // 根据正解几何，当 a2 * cos(th2) + d4 * sin(th2 + th3) 接近 0 时，
    // 意味着腕心在水平面上的投影半径 rXY 趋近于 0。
    double rXY = a2 * cos(th2) + d4 * sin(th2 + th3);
    bool shoulderSingular = rXY.abs() < 1e-3;

    return wristSingular || elbowSingular || shoulderSingular;
  }

  static double normalizeAngle(double angle) {
    double a = angle % (2 * pi);
    if (a > pi) a -= 2 * pi;
    if (a < -pi) a += 2 * pi;
    return a;
  }
}
