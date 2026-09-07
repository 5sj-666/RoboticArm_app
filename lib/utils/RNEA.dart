import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

/// 连杆动力学参数结构体
class LinkData {
  final double mass; // 质量 (kg)
  final Vector3 rc; // 连杆本地坐标系下的质心位置 (m)
  final Matrix3 inertia; // 质心处且对齐本地坐标系的惯性张量 (kg·m²)
  final double alpha; // MDH 参数: alpha_{i-1}
  final double a; // MDH 参数: a_{i-1}
  final double d; // MDH 参数: d_i

  LinkData({
    required this.mass,
    required this.rc,
    required this.inertia,
    required this.alpha,
    required this.a,
    required this.d,
  });
}

class ArmDynamicsSolver {
  late final List<LinkData> links;

  ArmDynamicsSolver() {
    // 录入实测质量属性与 MDH 参数
    links = [
      // Link 1
      LinkData(
        mass: 0.4716,
        rc: Vector3(0.0000, -0.0323, 0.0487),
        inertia: Matrix3(
          0.0008,
          0.0000,
          0.0000,
          0.0000,
          0.0005,
          0.0000,
          0.0000,
          0.0000,
          0.0008,
        ),
        alpha: 0.0,
        a: 0.0,
        d: 0.107,
      ),
      // Link 2 (已修正 X 轴方向为正)
      LinkData(
        mass: 0.5741,
        rc: Vector3(0.2362, 0.0000, 0.0222),
        inertia: Matrix3(
          0.0004,
          0.0000,
          -0.0002,
          0.0000,
          0.0064,
          0.0000,
          -0.0002,
          0.0000,
          0.0066,
        ),
        alpha: math.pi / 2,
        a: 0.0,
        d: 0.0,
      ),
      // Link 3
      LinkData(
        // mass: 0.5138,
        mass: 0,
        rc: Vector3(0.0380, 0.0000, -0.0630),
        inertia: Matrix3(
          0.0007,
          0.0000,
          0.0000,
          0.0000,
          0.0009,
          0.0000,
          0.0000,
          0.0000,
          0.0008,
        ),
        alpha: 0.0,
        a: 0.3,
        d: 0.0,
      ),
      // Link 4
      LinkData(
        // mass: 0.6280,
        mass: 0,
        rc: Vector3(0.0027, -0.0466, 0.1746),
        inertia: Matrix3(
          0.0066,
          0.0001,
          -0.0003,
          0.0001,
          0.0063,
          -0.0014,
          -0.0003,
          -0.0014,
          0.0010,
        ),
        alpha: -math.pi / 2,
        a: 0.0,
        d: 0.32315,
      ),
      // Link 5
      LinkData(
        // mass: 0.4290,
        mass: 0,
        rc: Vector3(0.0000, 0.0354, -0.0431),
        inertia: Matrix3(
          0.0004,
          0.0000,
          0.0000,
          0.0000,
          0.0004,
          0.0000,
          0.0000,
          0.0000,
          0.0004,
        ),
        alpha: math.pi / 2,
        a: 0.0,
        d: 0.0,
      ),
      // Link 6
      LinkData(
        // mass: 0.0041,
        mass: 0,
        rc: Vector3(0.0000, 0.0000, 0.0020),
        inertia: Matrix3(
          0.0000,
          0.0000,
          0.0000,
          0.0000,
          0.0000,
          0.0000,
          0.0000,
          0.0000,
          0.0000,
        ),
        alpha: -math.pi / 2,
        a: 0.0,
        d: 0.0825,
      ),
    ];
  }

  /// MDH 旋转矩阵 R_{i-1}^i
  Matrix3 _getMDHRotation(double alpha, double theta) {
    final ca = math.cos(alpha);
    final sa = math.sin(alpha);
    final ct = math.cos(theta);
    final st = math.sin(theta);

    return Matrix3.columns(
      Vector3(ct, st * ca, st * sa), // Column 0
      Vector3(-st, ct * ca, ct * sa), // Column 1
      Vector3(0.0, -sa, ca), // Column 2
    );
  }

  /// MDH 平移向量 P_{i-1}^i
  Vector3 _getMDHTranslation(double alpha, double a, double d) {
    return Vector3(a, -d * math.sin(alpha), d * math.cos(alpha));
  }

  /// RNEA 求解主函数 (输入单位均为 rad, rad/s, rad/s^2)
  List<double> computeTorques(
    List<double> q,
    List<double> dq,
    List<double> ddq, {
    Vector3? gravity,
  }) {
    final g = gravity ?? Vector3(0.0, 0.0, -9.81);

    // 存储前向外推的运动学状态
    List<Vector3> w = List.generate(6, (_) => Vector3.zero());
    List<Vector3> dw = List.generate(6, (_) => Vector3.zero());
    List<Vector3> a = List.generate(6, (_) => Vector3.zero());
    List<Vector3> ac = List.generate(6, (_) => Vector3.zero());
    List<Vector3> F = List.generate(6, (_) => Vector3.zero());
    List<Vector3> N = List.generate(6, (_) => Vector3.zero());
    List<Matrix3> R = List.generate(6, (_) => Matrix3.identity());
    List<Vector3> P = List.generate(6, (_) => Vector3.zero());

    // 1. 前向递归 (i = 0 -> 5，对应关节 1 -> 6)
    for (int i = 0; i < 6; i++) {
      final link = links[i];
      // ignore: non_constant_identifier_names
      final R_i_prev = _getMDHRotation(link.alpha, q[i]);
      R[i] = R_i_prev;
      P[i] = _getMDHTranslation(link.alpha, link.a, link.d);

      // ignore: non_constant_identifier_names
      final R_trans = Matrix3.copy(R_i_prev)..transpose();

      // ignore: non_constant_identifier_names
      final w_prev = i == 0 ? Vector3.zero() : w[i - 1];
      // ignore: non_constant_identifier_names
      final dw_prev = i == 0 ? Vector3.zero() : dw[i - 1];
      // ignore: non_constant_identifier_names
      final a_prev = i == 0 ? (R_trans * (-g)) : a[i - 1];

      // ignore: non_constant_identifier_names
      final z_axis = Vector3(0.0, 0.0, 1.0);

      // 角速度 w_i = R^T * w_{i-1} + dq_i * z
      w[i] = (R_trans * w_prev) + (z_axis * dq[i]);

      // 角加速度 dw_i = R^T * dw_{i-1} + ddq_i * z + (R^T * w_{i-1}) x (dq_i * z)
      // ignore: non_constant_identifier_names
      final w_rot = R_trans * w_prev;
      dw[i] =
          (R_trans * dw_prev) + (z_axis * ddq[i]) + w_rot.cross(z_axis * dq[i]);

      // 坐标原点加速度 a_i = R^T * a_{i-1} + dw_i x P_i + w_i x (w_i x P_i)
      a[i] =
          (R_trans * a_prev) + dw[i].cross(P[i]) + w[i].cross(w[i].cross(P[i]));

      // 质心加速度 ac_i = a_i + dw_i x rc_i + w_i x (w_i x rc_i)
      ac[i] = a[i] + dw[i].cross(link.rc) + w[i].cross(w[i].cross(link.rc));

      // 作用在质心上的净力 F_i 与净力矩 N_i
      F[i] = ac[i] * link.mass;
      N[i] = (link.inertia * dw[i]) + w[i].cross(link.inertia * w[i]);
    }

    // 2. 反向递归 (i = 5 -> 0，对应关节 6 -> 1)
    List<double> torques = List.filled(6, 0.0);
    // ignore: non_constant_identifier_names
    Vector3 f_next = Vector3.zero();
    // ignore: non_constant_identifier_names
    Vector3 n_next = Vector3.zero();

    for (int i = 5; i >= 0; i--) {
      final link = links[i];

      // ignore: non_constant_identifier_names
      Matrix3 R_succ = i == 5 ? Matrix3.identity() : R[i + 1];
      // ignore: non_constant_identifier_names
      Vector3 P_succ = i == 5 ? Vector3.zero() : P[i + 1];

      // 关节传导力 f_i = R_{i+1} * f_{i+1} + F_i
      // ignore: non_constant_identifier_names
      Vector3 f_i = (R_succ * f_next) + F[i];

      // 关节传导力矩 n_i = N_i + R_{i+1} * n_{i+1} + rc_i x F_i + P_{i+1} x (R_{i+1} * f_{i+1})
      // ignore: non_constant_identifier_names
      Vector3 n_i =
          N[i] +
          (R_succ * n_next) +
          link.rc.cross(F[i]) +
          P_succ.cross(R_succ * f_next);

      // 沿旋转轴 Z 的投影力矩
      torques[i] = n_i.z;

      f_next = f_i;
      n_next = n_i;
    }

    return torques;
  }
}
