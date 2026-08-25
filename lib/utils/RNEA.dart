import 'dart:math' as math;

/// RNEA 求解器
class ArmDynamicsSolver {
  late final List<LinkData> _links;

  ArmDynamicsSolver() {
    // 自动代入先前导出的 SolidWorks 质量属性与 MDH 参数
    _links = [
      // Link 1
      LinkData(
        alpha: 0.0,
        a: 0.0,
        d: 0.107,
        m: 0.47157,
        rc: Vector3(-0.00005, 0.08519, 0.03233),
        Ic: Matrix3([
          [0.00061, 0.00000, 0.00000],
          [0.00000, 0.00078, -0.00002],
          [0.00000, -0.00002, 0.00049],
        ]),
      ),
      // Link 2
      LinkData(
        alpha: math.pi / 2,
        a: 0.0,
        d: 0.0,
        m: 0.57413,
        rc: Vector3(-0.23618, -0.05815, 0.00002),
        Ic: Matrix3([
          [0.00042, 0.00018, 0.00000],
          [0.00018, 0.00660, 0.00000],
          [0.00000, 0.00000, 0.00640],
        ]),
      ),
      // Link 3
      LinkData(
        alpha: 0.0,
        a: 0.3,
        d: 0.0,
        m: 0.51377,
        rc: Vector3(-0.03804, 0.02951, 0.00002),
        Ic: Matrix3([
          [0.00070, -0.00004, 0.00000],
          [-0.00004, 0.00080, 0.00000],
          [0.00000, 0.00000, 0.00094],
        ]),
      ),
      // Link 4
      LinkData(
        alpha: -math.pi / 2,
        a: 0.0,
        d: 0.32315,
        m: 0.62797,
        rc: Vector3(-0.21108, -0.04658, 0.00275),
        Ic: Matrix3([
          [0.00096, 0.000138, 0.00025],
          [0.000138, 0.00628, -0.00025],
          [0.00025, -0.00025, 0.00656],
        ]),
      ),
      // Link 5
      LinkData(
        alpha: math.pi / 2,
        a: 0.0,
        d: 0.0,
        m: 0.42900,
        rc: Vector3(0.03542, 0.00109, 0.00002),
        Ic: Matrix3([
          [0.00041, 0.00002, 0.00000],
          [0.00002, 0.00044, 0.00000],
          [0.00000, 0.00000, 0.00045],
        ]),
      ),
      // Link 6
      LinkData(
        alpha: -math.pi / 2,
        a: 0.0,
        d: 0.0825,
        m: 0.00412,
        rc: Vector3(0.00000, 0.03847, 0.00000),
        Ic: Matrix3([
          [0.00001, 0.00000, 0.00000],
          [0.00000, 0.00000, 0.00000],
          [0.00000, 0.00000, 0.00001],
        ]),
      ),
    ];
  }

  /// 计算 MDH 旋转矩阵 R_{i, i-1} (系 {i-1} 到系 {i} 的旋转变换)
  Matrix3 _getRotationMatrix(double alpha, double theta) {
    double ca = math.cos(alpha);
    double sa = math.sin(alpha);
    double ct = math.cos(theta);
    double st = math.sin(theta);

    return Matrix3([
      [ct, st * ca, st * sa],
      [-st, ct * ca, ct * sa],
      [0, -sa, ca],
    ]);
  }

  /// 求解关节力矩 Tau (N·m)
  /// [q]: 关节角度列表 (rad), 长度 6
  /// [dq]: 关节角速度列表 (rad/s), 长度 6
  /// [ddq]: 关节角加速度列表 (rad/s^2), 长度 6
  List<double> computeTorques(
    List<double> q,
    List<double> dq,
    List<double> ddq,
  ) {
    int n = 6;
    List<Matrix3> R = [];
    List<Vector3> P = [];
    List<Vector3> w = List.generate(n, (_) => Vector3.zero());
    List<Vector3> dw = List.generate(n, (_) => Vector3.zero());
    List<Vector3> a = List.generate(n, (_) => Vector3.zero());
    List<Vector3> F = List.generate(n, (_) => Vector3.zero());
    List<Vector3> N = List.generate(n, (_) => Vector3.zero());

    // 初始状态（基座隐式加入 9.81 m/s^2 重力加速度）
    Vector3 wPrev = Vector3.zero();
    Vector3 dwPrev = Vector3.zero();
    Vector3 aPrev = Vector3(0.0, 0.0, 9.81);

    Vector3 zAxis = Vector3(0.0, 0.0, 1.0);

    // 1. 正向递归 (i = 0 到 5, 对应 Link 1 到 6)
    for (int i = 0; i < n; i++) {
      LinkData link = _links[i];
      // ignore: non_constant_identifier_names
      Matrix3 Ri = _getRotationMatrix(link.alpha, q[i]);
      R.add(Ri);

      // 计算原点相对位置 P_i (在系 {i} 中表示)
      Vector3 pInPrev = Vector3(
        link.a,
        -link.d * math.sin(link.alpha),
        link.d * math.cos(link.alpha),
      );
      // ignore: non_constant_identifier_names
      Vector3 Pi = Ri.multiplyVector(pInPrev);
      P.add(Pi);

      // 角速度与角加速度递推
      Vector3 wRot = Ri.multiplyVector(wPrev);
      w[i] = wRot + zAxis * dq[i];

      Vector3 dwRot = Ri.multiplyVector(dwPrev);
      dw[i] = dwRot + zAxis * ddq[i] + w[i].cross(zAxis * dq[i]);

      // 连杆原点与质心加速度递推
      a[i] =
          Ri.multiplyVector(aPrev) +
          dw[i].cross(Pi) +
          w[i].cross(w[i].cross(Pi));
      Vector3 aci =
          a[i] + dw[i].cross(link.rc) + w[i].cross(w[i].cross(link.rc));

      // 合外力与合外力矩
      F[i] = aci * link.m;
      N[i] =
          link.Ic.multiplyVector(dw[i]) +
          w[i].cross(link.Ic.multiplyVector(w[i]));

      wPrev = w[i];
      dwPrev = dw[i];
      aPrev = a[i];
    }

    // 2. 逆向递归 (i = 5 到 0, 对应 Link 6 到 1)
    List<double> torques = List.filled(n, 0.0);
    Vector3 fNext = Vector3.zero();
    Vector3 nNext = Vector3.zero();

    for (int i = n - 1; i >= 0; i--) {
      LinkData link = _links[i];
      Vector3 fInI = Vector3.zero();
      Vector3 nInI = Vector3.zero();

      if (i < n - 1) {
        // 次级连杆系到本级的变换矩阵 R_{i+1, i}^T
        // ignore: non_constant_identifier_names
        Matrix3 RNextTrans = R[i + 1].transpose();
        fInI = RNextTrans.multiplyVector(fNext);
        nInI = RNextTrans.multiplyVector(nNext);
      }

      Vector3 fi = fInI + F[i];

      // P_{i+1} 在系 {i} 中的表示
      LinkData nextLink = (i < n - 1) ? _links[i + 1] : _links[i];
      Vector3 pNextInI = (i < n - 1)
          ? Vector3(
              link.a,
              -nextLink.d * math.sin(link.alpha),
              nextLink.d * math.cos(link.alpha),
            )
          : Vector3.zero();

      Vector3 ni = nInI + N[i] + link.rc.cross(F[i]) + pNextInI.cross(fInI);

      // Z 轴方向分量即为关节电机输出力矩
      torques[i] = ni.z;

      fNext = fi;
      nNext = ni;
    }

    return torques;
  }
}

/// 3D 向量类
class Vector3 {
  double x, y, z;
  Vector3(this.x, this.y, this.z);

  Vector3 operator +(Vector3 o) => Vector3(x + o.x, y + o.y, z + o.z);
  Vector3 operator -(Vector3 o) => Vector3(x - o.x, y - o.y, z - o.z);
  Vector3 operator *(double s) => Vector3(x * s, y * s, z * s);

  double dot(Vector3 o) => x * o.x + y * o.y + z * o.z;

  Vector3 cross(Vector3 o) =>
      Vector3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  static Vector3 zero() => Vector3(0, 0, 0);
}

/// 3x3 矩阵类
class Matrix3 {
  final List<List<double>> m;

  Matrix3(this.m);

  Vector3 multiplyVector(Vector3 v) {
    return Vector3(
      m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z,
      m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z,
      m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z,
    );
  }

  Matrix3 transpose() {
    return Matrix3([
      [m[0][0], m[1][0], m[2][0]],
      [m[0][1], m[1][1], m[2][1]],
      [m[0][2], m[1][2], m[2][2]],
    ]);
  }
}

/// 连杆动力学与 MDH 参数结构体
class LinkData {
  final double alpha; // MDH alpha_{i-1} (rad)
  final double a; // MDH a_{i-1} (m)
  final double d; // MDH d_i (m)
  final double m; // 连杆质量 (kg)
  final Vector3 rc; // 本地质心位置 (m)
  // ignore: non_constant_identifier_names
  final Matrix3 Ic; // 本地质心惯性张量 (kg*m^2)

  LinkData({
    required this.alpha,
    required this.a,
    required this.d,
    required this.m,
    required this.rc,
    // ignore: non_constant_identifier_names
    required this.Ic,
  });
}
