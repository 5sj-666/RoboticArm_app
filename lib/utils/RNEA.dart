// import 'dart:math' as math;

// /// 三维向量类
// class Vector3 {
//   double x, y, z;

//   Vector3([this.x = 0.0, this.y = 0.0, this.z = 0.0]);

//   Vector3 operator +(Vector3 b) => Vector3(x + b.x, y + b.y, z + b.z);
//   Vector3 operator -(Vector3 b) => Vector3(x - b.x, y - b.y, z - b.z);
//   Vector3 operator *(double s) => Vector3(x * s, y * s, z * s);

//   /// 向量叉乘
//   Vector3 cross(Vector3 b) {
//     return Vector3(
//       y * b.z - z * b.y,
//       z * b.x - x * b.z,
//       x * b.y - y * b.x,
//     );
//   }

//   /// 向量点乘
//   double dot(Vector3 b) => x * b.x + y * b.y + z * b.z;
// }

// /// 3x3 矩阵类
// class Matrix3x3 {
//   List<List<double>> m;

//   Matrix3x3() : m = List.generate(3, (_) => List.filled(3, 0.0));

//   /// 矩阵乘以向量
//   Vector3 multiplyVector(Vector3 v) {
//     return Vector3(
//       m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z,
//       m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z,
//       m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z,
//     );
//   }

//   /// 矩阵转置
//   Matrix3x3 transpose() {
//     Matrix3x3 res = Matrix3x3();
//     for (int i = 0; i < 3; i++) {
//       for (int j = 0; j < 3; j++) {
//         res.m[i][j] = m[j][i];
//       }
//     }
//     return res;
//   }
// }

// /// 连杆动力学参数类
// class LinkParams {
//   double alphaPrev; // alpha_{i-1}
//   double aPrev;     // a_{i-1}
//   double d;          // d_i
//   double m;          // 质量 (kg)
//   Vector3 rC;        // 质心在 MDH Frame i 下的位置 (m)
//   Matrix3x3 iO;      // MDH Frame i 原点处的惯量张量 (kg·m²)

//   LinkParams({
//     required this.alphaPrev,
//     required this.aPrev,
//     required this.d,
//     required this.m,
//     required this.rC,
//     Matrix3x3? iO,
//   }) : iO = iO ?? Matrix3x3();
// }

// /// 递归牛顿-欧拉算法（RNEA）计算函数（无腕部电机轻量测试版）
// ///
// /// 输入参数：
// /// - [q]: 各关节角度，单位：弧度 (rad)
// /// - [dq]: 各关节角速度，单位：rad/s
// /// - [ddq]: 各关节角加速度，单位：rad/s^2
// /// - [gBase]: 基座重力加速度向量，默认竖直向下 [0, 0, -9.81] m/s^2
// ///
// /// 返回：各关节所需的驱动力矩 List<double>，单位：N·m
// List<double> computeRNEA(
//   List<double> q,
//   List<double> dq,
//   List<double> ddq, {
//   Vector3? gBase,
// }) {
//   final Vector3 gravity = gBase ?? Vector3(0.0, 0.0, -9.81);
//   const int n = 6;

//   // 初始化 6 个连杆的 MDH 参数与【不含腕部电机】的几何惯量数据
//   final List<LinkParams> links = [
//     LinkParams(
//       alphaPrev: 0.0,
//       aPrev: 0.0,
//       d: 0.107,
//       m: 0.4716,
//       rC: Vector3(0.0000, -0.0323, -0.0018),
//     ),
//     LinkParams(
//       alphaPrev: math.pi / 2,
//       aPrev: 0.0,
//       d: 0.0,
//       m: 0.5741,
//       rC: Vector3(0.2362, 0.0000, 0.0897),
//     ),
//     LinkParams(
//       alphaPrev: 0.0,
//       aPrev: 0.3,
//       d: 0.0,
//       m: 0.1968,
//       rC: Vector3(0.0000, 0.0113, 0.0054),
//     ),
//     LinkParams(
//       alphaPrev: -math.pi / 2,
//       aPrev: 0.0,
//       d: 0.32315,
//       m: 0.3110,
//       rC: Vector3(-0.0055, 0.0324, -0.1524),
//     ),
//     LinkParams(
//       alphaPrev: math.pi / 2,
//       aPrev: 0.0,
//       d: 0.0,
//       m: 0.1120,
//       rC: Vector3(0.0000, 0.0098, -0.0047),
//     ),
//     LinkParams(
//       alphaPrev: -math.pi / 2,
//       aPrev: 0.0,
//       d: 0.0,
//       m: 0.0041,
//       rC: Vector3(0.0000, -0.0030, 0.0650),
//     ),
//   ];

//   // Link 1 原点惯量
//   links[0].iO.m[0][0] = 0.0013; links[0].iO.m[1][1] = 0.0005; links[0].iO.m[2][2] = 0.0013;

//   // Link 2 原点惯量
//   links[1].iO.m[0][0] = 0.0050; links[1].iO.m[1][1] = 0.0430; links[1].iO.m[2][2] = 0.0386;
//   links[1].iO.m[0][2] = -0.0120; links[1].iO.m[2][0] = -0.0120;

//   // Link 3 原点惯量 (无电机)
//   links[2].iO.m[0][0] = 0.0006; links[2].iO.m[1][1] = 0.0005; links[2].iO.m[2][2] = 0.0005;

//   // Link 4 原点惯量 (无电机)
//   links[3].iO.m[0][0] = 0.0102; links[3].iO.m[1][1] = 0.0097; links[3].iO.m[2][2] = 0.0011;
//   links[3].iO.m[0][2] = 0.0004; links[3].iO.m[2][0] = 0.0004;
//   links[3].iO.m[1][2] = -0.0008; links[3].iO.m[2][1] = -0.0008;

//   // Link 5 原点惯量 (无电机)
//   links[4].iO.m[0][0] = 0.0002; links[4].iO.m[1][1] = 0.0002; links[4].iO.m[2][2] = 0.0002;

//   // Link 6 原点惯量 (保持为 0)

//   final List<Vector3> w = List.generate(n, (_) => Vector3());
//   final List<Vector3> dw = List.generate(n, (_) => Vector3());
//   final List<Vector3> a = List.generate(n, (_) => Vector3());
//   final List<Vector3> aC = List.generate(n, (_) => Vector3());
//   final List<Vector3> fC = List.generate(n, (_) => Vector3());
//   final List<Vector3> nC = List.generate(n, (_) => Vector3());
//   final List<Matrix3x3> rIPrev = List.generate(n, (_) => Matrix3x3());

//   Vector3 wPrev = Vector3(0, 0, 0);
//   Vector3 dwPrev = Vector3(0, 0, 0);
//   Vector3 aPrev = gravity * -1.0;
//   final Vector3 zHat = Vector3(0, 0, 1.0);

//   // ================= 1. 前向递推 (Forward Recursion) =================
//   for (int i = 0; i < n; i++) {
//     final double theta = q[i];
//     final double ct = math.cos(theta);
//     final double st = math.sin(theta);
//     final double ca = math.cos(links[i].alphaPrev);
//     final double sa = math.sin(links[i].alphaPrev);

//     final Matrix3x3 r = Matrix3x3();
//     r.m[0][0] = ct;  r.m[0][1] = st * ca;  r.m[0][2] = st * sa;
//     r.m[1][0] = -st; r.m[1][1] = ct * ca;  r.m[1][2] = ct * sa;
//     r.m[2][0] = 0.0; r.m[2][1] = -sa;      r.m[2][2] = ca;
//     rIPrev[i] = r;

//     final Vector3 wInI = r.multiplyVector(wPrev);
//     final Vector3 dwInI = r.multiplyVector(dwPrev);

//     w[i] = wInI + zHat * dq[i];
//     dw[i] = dwInI + wInI.cross(zHat * dq[i]) + zHat * ddq[i];

//     final Vector3 pInI = Vector3(
//       links[i].aPrev * ct,
//       -links[i].aPrev * st,
//       links[i].d,
//     );
//     a[i] = r.multiplyVector(aPrev) +
//         dwInI.cross(pInI) +
//         wInI.cross(wInI.cross(pInI));

//     aC[i] = a[i] +
//         dw[i].cross(links[i].rC) +
//         w[i].cross(w[i].cross(links[i].rC));

//     // 平行轴定理转换惯量张量
//     final Matrix3x3 iC = Matrix3x3();
//     final double m = links[i].m;
//     final double xc = links[i].rC.x;
//     final double yc = links[i].rC.y;
//     final double zc = links[i].rC.z;

//     iC.m[0][0] = links[i].iO.m[0][0] - m * (yc * yc + zc * zc);
//     iC.m[1][1] = links[i].iO.m[1][1] - m * (xc * xc + zc * zc);
//     iC.m[2][2] = links[i].iO.m[2][2] - m * (xc * xc + yc * yc);
//     iC.m[0][1] = links[i].iO.m[0][1] + m * xc * yc;
//     iC.m[1][0] = iC.m[0][1];
//     iC.m[0][2] = links[i].iO.m[0][2] + m * xc * zc;
//     iC.m[2][0] = iC.m[0][2];
//     iC.m[1][2] = links[i].iO.m[1][2] + m * yc * zc;
//     iC.m[2][1] = iC.m[1][2];

//     fC[i] = aC[i] * m;
//     nC[i] = iC.multiplyVector(dw[i]) + w[i].cross(iC.multiplyVector(w[i]));

//     wPrev = w[i];
//     dwPrev = dw[i];
//     aPrev = a[i];
//   }

//   // ================= 2. 后向递推 (Backward Recursion) =================
//   final List<double> tau = List.filled(n, 0.0);
//   Vector3 fNext = Vector3(0, 0, 0);
//   Vector3 nNext = Vector3(0, 0, 0);

//   for (int i = n - 1; i >= 0; i--) {
//     Vector3 fCurr = fC[i];
//     Vector3 nCurr = nC[i] + links[i].rC.cross(fC[i]);

//     if (i < n - 1) {
//       final Matrix3x3 rNextCurr = rIPrev[i + 1].transpose();
//       final Vector3 fNextInCurr = rNextCurr.multiplyVector(fNext);
//       final Vector3 nNextInCurr = rNextCurr.multiplyVector(nNext);

//       final Vector3 pNextInCurr = Vector3(
//         links[i + 1].aPrev,
//         -links[i + 1].d * math.sin(links[i + 1].alphaPrev),
//         links[i + 1].d * math.cos(links[i + 1].alphaPrev),
//       );

//       fCurr = fCurr + fNextInCurr;
//       nCurr = nCurr + nNextInCurr + pNextInCurr.cross(fNextInCurr);
//     }

//     tau[i] = nCurr.z;

//     fNext = fCurr;
//     nNext = nCurr;
//   }

//   return tau;
// }

import 'dart:math' as math;

/// 三维向量类
class Vector3 {
  double x, y, z;

  Vector3([this.x = 0.0, this.y = 0.0, this.z = 0.0]);

  Vector3 operator +(Vector3 b) => Vector3(x + b.x, y + b.y, z + b.z);
  Vector3 operator -(Vector3 b) => Vector3(x - b.x, y - b.y, z - b.z);
  Vector3 operator *(double s) => Vector3(x * s, y * s, z * s);

  /// 向量叉乘
  Vector3 cross(Vector3 b) {
    return Vector3(y * b.z - z * b.y, z * b.x - x * b.z, x * b.y - y * b.x);
  }

  /// 向量点乘
  double dot(Vector3 b) => x * b.x + y * b.y + z * b.z;
}

/// 3x3 矩阵类
class Matrix3x3 {
  List<List<double>> m;

  Matrix3x3() : m = List.generate(3, (_) => List.filled(3, 0.0));

  /// 矩阵乘以向量
  Vector3 multiplyVector(Vector3 v) {
    return Vector3(
      m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z,
      m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z,
      m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z,
    );
  }

  /// 矩阵转置
  Matrix3x3 transpose() {
    Matrix3x3 res = Matrix3x3();
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        res.m[i][j] = m[j][i];
      }
    }
    return res;
  }
}

/// 连杆动力学参数类
class LinkParams {
  double alphaPrev; // alpha_{i-1}
  double aPrev; // a_{i-1}
  double d; // d_i
  double m; // 质量 (kg)
  Vector3 rC; // 质心在 MDH Frame i 下的位置 (m)
  Matrix3x3 iO; // MDH Frame i 原点处的惯量张量 (kg·m²)

  LinkParams({
    required this.alphaPrev,
    required this.aPrev,
    required this.d,
    required this.m,
    required this.rC,
    Matrix3x3? iO,
  }) : iO = iO ?? Matrix3x3();
}

/// 递归牛顿-欧拉算法（RNEA）计算函数（无腕部电机轻量测试版）
///
/// 输入参数：
/// - [q]: 各关节角度，单位：弧度 (rad)
/// - [dq]: 各关节角速度，单位：rad/s
/// - [ddq]: 各关节角加速度，单位：rad/s^2
/// - [gBase]: 基座重力加速度向量，默认竖直向下 [0, 0, -9.81] m/s^2
///
/// 返回：各关节所需的驱动力矩 List<double>，单位：N·m
List<double> computeRNEA(
  List<double> q,
  List<double> dq,
  List<double> ddq, {
  Vector3? gBase,
}) {
  final Vector3 gravity = gBase ?? Vector3(0.0, 0.0, -9.81);
  const int n = 6;

  // 初始化 6 个连杆的 MDH 参数与【不含腕部电机】的几何惯量数据
  final List<LinkParams> links = [
    LinkParams(
      alphaPrev: 0.0,
      aPrev: 0.0,
      d: 0.107,
      m: 0.4716,
      rC: Vector3(0.0000, -0.0323, -0.0018),
    ),
    LinkParams(
      alphaPrev: math.pi / 2,
      aPrev: 0.0,
      d: 0.0,
      // m: 0.5741,
      m: 0.5395,
      rC: Vector3(0.2362, 0.0000, 0.0897),
    ),
    LinkParams(
      alphaPrev: 0.0,
      aPrev: 0.3,
      d: 0.0,
      // m: 0.1968,
      m: 0.129,
      rC: Vector3(0.0000, 0.0113, 0.0054),
    ),
    LinkParams(
      alphaPrev: -math.pi / 2,
      aPrev: 0.0,
      d: 0.32315,
      // m: 0.3110,
      m: 0.205,
      rC: Vector3(-0.0055, 0.0324, -0.1524),
    ),
    LinkParams(
      alphaPrev: math.pi / 2,
      aPrev: 0.0,
      d: 0.0,
      // m: 0.1120,
      m: 0.09,
      rC: Vector3(0.0000, 0.0098, -0.0047),
    ),
    LinkParams(
      alphaPrev: -math.pi / 2,
      aPrev: 0.0,
      d: 0.0,
      // m: 0.0041,
      m: 0.00,
      rC: Vector3(0.0000, -0.0030, 0.0650),
    ),
  ];

  // Link 1 原点惯量
  links[0].iO.m[0][0] = 0.0013;
  links[0].iO.m[1][1] = 0.0005;
  links[0].iO.m[2][2] = 0.0013;

  // Link 2 原点惯量
  links[1].iO.m[0][0] = 0.0050;
  links[1].iO.m[1][1] = 0.0430;
  links[1].iO.m[2][2] = 0.0386;
  links[1].iO.m[0][2] = -0.0120;
  links[1].iO.m[2][0] = -0.0120;

  // Link 3 原点惯量 (无电机)
  links[2].iO.m[0][0] = 0.0006;
  links[2].iO.m[1][1] = 0.0005;
  links[2].iO.m[2][2] = 0.0005;

  // Link 4 原点惯量 (无电机)
  links[3].iO.m[0][0] = 0.0102;
  links[3].iO.m[1][1] = 0.0097;
  links[3].iO.m[2][2] = 0.0011;
  links[3].iO.m[0][2] = 0.0004;
  links[3].iO.m[2][0] = 0.0004;
  links[3].iO.m[1][2] = -0.0008;
  links[3].iO.m[2][1] = -0.0008;

  // Link 5 原点惯量 (无电机)
  links[4].iO.m[0][0] = 0.0002;
  links[4].iO.m[1][1] = 0.0002;
  links[4].iO.m[2][2] = 0.0002;

  // Link 6 原点惯量 (保持为 0)

  final List<Vector3> w = List.generate(n, (_) => Vector3());
  final List<Vector3> dw = List.generate(n, (_) => Vector3());
  final List<Vector3> a = List.generate(n, (_) => Vector3());
  final List<Vector3> aC = List.generate(n, (_) => Vector3());
  final List<Vector3> fC = List.generate(n, (_) => Vector3());
  final List<Vector3> nC = List.generate(n, (_) => Vector3());
  final List<Matrix3x3> rIPrev = List.generate(n, (_) => Matrix3x3());

  Vector3 wPrev = Vector3(0, 0, 0);
  Vector3 dwPrev = Vector3(0, 0, 0);
  Vector3 aPrev = gravity * -1.0;
  final Vector3 zHat = Vector3(0, 0, 1.0);

  // ================= 1. 前向递推 (Forward Recursion) =================
  for (int i = 0; i < n; i++) {
    final double theta = q[i];
    final double ct = math.cos(theta);
    final double st = math.sin(theta);
    final double ca = math.cos(links[i].alphaPrev);
    final double sa = math.sin(links[i].alphaPrev);

    final Matrix3x3 r = Matrix3x3();
    r.m[0][0] = ct;
    r.m[0][1] = st * ca;
    r.m[0][2] = st * sa;
    r.m[1][0] = -st;
    r.m[1][1] = ct * ca;
    r.m[1][2] = ct * sa;
    r.m[2][0] = 0.0;
    r.m[2][1] = -sa;
    r.m[2][2] = ca;
    rIPrev[i] = r;

    final Vector3 wInI = r.multiplyVector(wPrev);
    final Vector3 dwInI = r.multiplyVector(dwPrev);

    w[i] = wInI + zHat * dq[i];
    dw[i] = dwInI + wInI.cross(zHat * dq[i]) + zHat * ddq[i];

    final Vector3 pInI = Vector3(
      links[i].aPrev * ct,
      -links[i].aPrev * st,
      links[i].d,
    );
    a[i] =
        r.multiplyVector(aPrev) +
        dwInI.cross(pInI) +
        wInI.cross(wInI.cross(pInI));

    aC[i] =
        a[i] + dw[i].cross(links[i].rC) + w[i].cross(w[i].cross(links[i].rC));

    // 平行轴定理转换惯量张量
    final Matrix3x3 iC = Matrix3x3();
    final double m = links[i].m;
    final double xc = links[i].rC.x;
    final double yc = links[i].rC.y;
    final double zc = links[i].rC.z;

    iC.m[0][0] = links[i].iO.m[0][0] - m * (yc * yc + zc * zc);
    iC.m[1][1] = links[i].iO.m[1][1] - m * (xc * xc + zc * zc);
    iC.m[2][2] = links[i].iO.m[2][2] - m * (xc * xc + yc * yc);
    iC.m[0][1] = links[i].iO.m[0][1] + m * xc * yc;
    iC.m[1][0] = iC.m[0][1];
    iC.m[0][2] = links[i].iO.m[0][2] + m * xc * zc;
    iC.m[2][0] = iC.m[0][2];
    iC.m[1][2] = links[i].iO.m[1][2] + m * yc * zc;
    iC.m[2][1] = iC.m[1][2];

    fC[i] = aC[i] * m;
    nC[i] = iC.multiplyVector(dw[i]) + w[i].cross(iC.multiplyVector(w[i]));

    wPrev = w[i];
    dwPrev = dw[i];
    aPrev = a[i];
  }

  // ================= 2. 后向递推 (Backward Recursion) =================
  final List<double> tau = List.filled(n, 0.0);
  Vector3 fNext = Vector3(0, 0, 0);
  Vector3 nNext = Vector3(0, 0, 0);

  for (int i = n - 1; i >= 0; i--) {
    Vector3 fCurr = fC[i];
    Vector3 nCurr = nC[i] + links[i].rC.cross(fC[i]);

    if (i < n - 1) {
      final Matrix3x3 rNextCurr = rIPrev[i + 1].transpose();
      final Vector3 fNextInCurr = rNextCurr.multiplyVector(fNext);
      final Vector3 nNextInCurr = rNextCurr.multiplyVector(nNext);

      final Vector3 pNextInCurr = Vector3(
        links[i + 1].aPrev,
        -links[i + 1].d * math.sin(links[i + 1].alphaPrev),
        links[i + 1].d * math.cos(links[i + 1].alphaPrev),
      );

      fCurr = fCurr + fNextInCurr;
      nCurr = nCurr + nNextInCurr + pNextInCurr.cross(fNextInCurr);
    }

    tau[i] = nCurr.z;

    fNext = fCurr;
    nNext = nCurr;
  }

  return tau;
}
