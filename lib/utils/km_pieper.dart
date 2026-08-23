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
        'quaternion:  ${quaternion.x.toStringAsFixed(3)}, ${quaternion.y.toStringAsFixed(3)}, ${quaternion.z.toStringAsFixed(3)}, ${quaternion.w.toStringAsFixed(3)} \n'
        'EulerXYZ: ${eulerXYZ.x.toStringAsFixed(3)}, ${eulerXYZ.y.toStringAsFixed(3)}, ${eulerXYZ.z.toStringAsFixed(3)}\n';
  }
}

class KmPieper {
  // 以下是soliworks精确的参数，与实体机械臂对应
  // static const double d1 = 0.107;
  // static const double a2 = 0.3;
  // static const double d4 = 0.32315;
  // static const double d6 = 0.0825;
  // 以下是app模型的参数，暂时用来做测试
  static const double d1 = 0.141;
  static const double a2 = 0.3;
  static const double d4 = 0.326;
  static const double d6 = 0.09;

  // 内部工具：角度与弧度转换
  static double _deg2rad(double deg) => deg * pi / 180.0;

  /// 运动学正解 (FK)
  /// 输入: 6个关节的角度 List<double> (单位: 度)
  /// 输出: 封装好的 KinematicResult 对象
  static KinematicResult fk(List<double> jointAnglesDeg) {
    jointAnglesDeg[1] = jointAnglesDeg[1] + 90;
    jointAnglesDeg[2] = jointAnglesDeg[2] - 90;

    if (jointAnglesDeg.length != 6) {
      throw Exception("需要6个关节的角度");
    }

    // 1. 将输入的角度转为弧度用于运算
    List<double> th = jointAnglesDeg.map((deg) => _deg2rad(deg)).toList();

    // 2. 构建变换矩阵
    List<List<double>> t1 = _mdhMatrix(0, 0, d1, th[0]);
    List<List<double>> t2 = _mdhMatrix(pi / 2, 0, 0, th[1]);
    List<List<double>> t3 = _mdhMatrix(0, a2, 0, th[2]);
    List<List<double>> t4 = _mdhMatrix(-pi / 2, 0, d4, th[3]);
    List<List<double>> t5 = _mdhMatrix(pi / 2, 0, 0, th[4]);
    List<List<double>> t6 = _mdhMatrix(-pi / 2, 0, d6, th[5]);

    // 连续相乘求得末端姿态 t06 (行主序)
    List<List<double>> t06 = _multiply(
      _multiply(_multiply(_multiply(_multiply(t1, t2), t3), t4), t5),
      t6,
    );

    // 3. 构建 Matrix4 变换矩阵 (将行主序转为列主序)
    final Matrix4 transformation = Matrix4(
      t06[0][0],
      t06[1][0],
      t06[2][0],
      t06[3][0],
      t06[0][1],
      t06[1][1],
      t06[2][1],
      t06[3][1],
      t06[0][2],
      t06[1][2],
      t06[2][2],
      t06[3][2],
      t06[0][3],
      t06[1][3],
      t06[2][3],
      t06[3][3],
    );

    // 4. 提取位移 Vector3
    final Vector3 position = Vector3(t06[0][3], t06[1][3], t06[2][3]);

    // 5. 提取姿态 Quaternion
    // 利用 vector_math 提供的 getRotation 方法提取 3x3 旋转矩阵，并直接生成四元数
    final Quaternion quaternion = Quaternion.fromRotation(
      transformation.getRotation(),
    );

    // 6. 计算 Euler XYZ 欧拉角 (单位: 弧度)
    // 采用标准 XYZ 顺规解析，并处理万向锁（奇异点）保护
    double sy = sqrt(t06[0][0] * t06[0][0] + t06[1][0] * t06[1][0]);
    bool singular = sy < 1e-6; // 检测是否发生万向锁

    double ex, ey, ez;
    if (!singular) {
      ex = atan2(t06[2][1], t06[2][2]);
      ey = atan2(-t06[2][0], sy);
      ez = atan2(t06[1][0], t06[0][0]);
    } else {
      // 处于万向锁状态时，强行将 z 轴旋转归零，完全由 x 轴补偿
      ex = atan2(-t06[1][2], t06[1][1]);
      ey = atan2(-t06[2][0], sy);
      ez = 0;
    }
    final Vector3 eulerXYZ = Vector3(ex, ey, ez);

    // 7. 返回结果
    return KinematicResult(
      position: position,
      quaternion: quaternion,
      eulerXYZ: eulerXYZ,
      transformation: transformation,
    );
  }

  /// 运动学逆解 (IK) - 返回所有可行的数学解（0 到 8 组）
  /// 输入: 期望的末端变换矩阵 Matrix4 targetPose
  /// 输出: 包含多组弧度解的列表 List<List<double>>

  static List<List<double>> ik(Matrix4 targetPose, List<double>? preJointRad) {
    preJointRad?[1] = preJointRad[1] + pi / 2;
    preJointRad?[2] = preJointRad[2] - pi / 2;

    List<List<double>> solutions = [];

    // 1. 提取目标位移和旋转矩阵元素
    double px = targetPose.entry(0, 3);
    double py = targetPose.entry(1, 3);
    double pz = targetPose.entry(2, 3);

    double r11 = targetPose.entry(0, 0);
    double r12 = targetPose.entry(0, 1);
    double r13 = targetPose.entry(0, 2);
    double r21 = targetPose.entry(1, 0);
    double r22 = targetPose.entry(1, 1);
    double r23 = targetPose.entry(1, 2);
    double r31 = targetPose.entry(2, 0);
    double r32 = targetPose.entry(2, 1);
    double r33 = targetPose.entry(2, 2);

    // 2. 反推球形腕中心点 (Wrist Center)
    double wx = px - d6 * r13;
    double wy = py - d6 * r23;
    double wz = pz - d6 * r33;

    // ==========================================
    // 【新增】：肩部奇异点处理 (Shoulder Singularity)
    // 跨越北极点： 锁定轴1为上一帧的值
    // ==========================================
    double rXySq = wx * wx + wy * wy;
    List<double> th1List = [];

    // 如果腕心水平投影半径极小 (1毫米以内视为奇异)
    if (rXySq < 1e-6) {
      // 锁定 θ1 为上一帧的角度，此时不再分正反向
      double prevTh1 = (preJointRad != null && preJointRad.isNotEmpty)
          ? preJointRad[0]
          : 0.0;
      th1List = [prevTh1];
    } else {
      // 正常区域，产生正反两个解
      th1List = [atan2(wy, wx), atan2(-wy, -wx)];
    }

    // --- 分支 1：肩部姿态 ---
    for (double th1 in th1List) {
      double r = sqrt(rXySq);
      // 如果肩部反向，r 取负值
      if ((th1 - atan2(wy, wx)).abs() > 1e-4) {
        r = -r;
      }
      double zPrime = wz - d1;

      // ==========================================
      // 肘部奇异点处理 (Elbow Singularity)： 可达空间的处理
      // 1.如果超过外部可达空间： 无解
      // 2.如果点位在于内部折叠导致的死区，大臂与小臂的差值：无解
      // ==========================================
      double sinTh3 =
          (a2 * a2 + d4 * d4 - (r * r + zPrime * zPrime)) / (2 * a2 * d4);

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
        double th2 = atan2(A * zPrime - B * r, A * r + B * zPrime);

        // 计算前置姿态 T03
        List<List<double>> t1 = _mdhMatrix(0, 0, d1, th1);
        List<List<double>> t2 = _mdhMatrix(pi / 2, 0, 0, th2);
        List<List<double>> t3m = _mdhMatrix(0, a2, 0, th3);
        List<List<double>> t03 = _multiply(_multiply(t1, t2), t3m);

        List<List<double>> r03T = [
          [t03[0][0], t03[1][0], t03[2][0]],
          [t03[0][1], t03[1][1], t03[2][1]],
          [t03[0][2], t03[1][2], t03[2][2]],
        ];

        List<List<double>> rTarget = [
          [r11, r12, r13],
          [r21, r22, r23],
          [r31, r32, r33],
        ];

        List<List<double>> r36 = List.generate(3, (_) => List.filled(3, 0.0));
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            for (int k = 0; k < 3; k++) {
              r36[i][j] += r03T[i][k] * rTarget[k][j];
            }
          }
        }

        double r36_12 = r36[1][2].clamp(-1.0, 1.0);

        // --- 分支 3：腕部姿态 (2种: 姿态正向 / 姿态翻转) ---
        double th5Base = acos(r36_12);
        List<double> th5List = [th5Base, -th5Base];

        for (double th5 in th5List) {
          double th4, th6;
          double sinTh5 = sin(th5);

          // ==========================================
          // 【修改】：腕部奇异点处理 (Wrist Singularity)
          // ==========================================
          if (sinTh5.abs() > 1e-4) {
            // 正常姿态：使用 Dart 的 .sign 属性来获取正负符号 (1.0 或 -1.0)
            double sign = sinTh5.sign;
            th4 = atan2(r36[2][2] * sign, -r36[0][2] * sign);
            th6 = atan2(-r36[1][1] * sign, r36[1][0] * sign);
          } else {
            // 奇异姿态 (Gimbal Lock)(第五轴角度为0时)：4轴和6轴重合
            if (preJointRad != null && preJointRad.length >= 6) {
              th4 = preJointRad[3]; // 核心：锁定 4轴 为上一帧的角度
              th6 = atan2(-r36[0][1], r36[0][0]) - th4; // 让 6轴 承担所有剩余的旋转补偿
            } else {
              th4 = 0.0;
              th6 = atan2(-r36[0][1], r36[0][0]);
            }
          }

          // solutions.add([th1, th2 - pi / 2, th3 + pi / 2, th4, th5, th6]);
          solutions.add(
            [
              th1,
              th2 - pi / 2,
              th3 + pi / 2,
              th4,
              th5,
              th6,
            ].map((e) => normalizeAngle(e)).toList(),
          );
          //  solutions.add(
          //   [q1, q2, q3, q4, q5, q6].map((e) => normalizeAngle(e)).toList(),
          // );
        }
      }
    }

    // 调试输出保持不变
    // print("---start---");
    // print("Solutions count: ${solutions.length}");
    // for (int i = 0; i < solutions.length; i++) {
    //   print(solutions[i].map((e) => _toDeg(e)).toList());
    // }
    // // print('---当前角度： ${preJointRad?.map((e) => _toDeg(e)).toList()}');
    // print("---end---");

    return solutions;
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

  /// 计算 6x6 几何雅可比矩阵 (Geometric Jacobian)
  /// 输入: 6个关节的角度 List<double> jointsRad (单位: 弧度)
  /// 输出: 6x6 矩阵，6行6列的二维数组，按行存储
  static List<List<double>> getJacobian(List<double> jointsRad) {
    if (jointsRad.length != 6) {
      throw Exception("需要6个关节的角度(弧度制)");
    }

    // 1. 计算各连杆坐标系相对于基座的变换矩阵 T0_i
    List<List<double>> t01 = _mdhMatrix(0, 0, d1, jointsRad[0]);
    List<List<double>> t02 = _multiply(
      t01,
      _mdhMatrix(pi / 2, 0, 0, jointsRad[1]),
    );
    List<List<double>> t03 = _multiply(t02, _mdhMatrix(0, a2, 0, jointsRad[2]));
    List<List<double>> t04 = _multiply(
      t03,
      _mdhMatrix(-pi / 2, 0, d4, jointsRad[3]),
    );
    List<List<double>> t05 = _multiply(
      t04,
      _mdhMatrix(pi / 2, 0, 0, jointsRad[4]),
    );
    List<List<double>> t06 = _multiply(
      t05,
      _mdhMatrix(-pi / 2, 0, d6, jointsRad[5]),
    );

    // 2. 提取末端 TCP (法兰盘中心) 的绝对位置 P6
    double p6x = t06[0][3];
    double p6y = t06[1][3];
    double p6z = t06[2][3];

    // 保存所有坐标系变换矩阵，便于迭代
    List<List<List<double>>> frames = [t01, t02, t03, t04, t05, t06];

    // 3. 初始化 6x6 雅可比矩阵 (6个自由度，6个关节)
    List<List<double>> jacobian = List.generate(6, (_) => List.filled(6, 0.0));

    // 4. 逐列计算雅可比矩阵
    for (int i = 0; i < 6; i++) {
      var mat = frames[i];

      // 提取第 i 个坐标系的 Z 轴方向向量 (即 MDH 约定的第 i 关节旋转轴 Z_i)
      double zx = mat[0][2];
      double zy = mat[1][2];
      double zz = mat[2][2];

      // 提取第 i 个坐标系的原点位置 P_i
      double px = mat[0][3];
      double py = mat[1][3];
      double pz = mat[2][3];

      // 计算力臂向量: P6 - Pi
      double dx = p6x - px;
      double dy = p6y - py;
      double dz = p6z - pz;

      // 计算线速度雅可比 (J_v) = Z_i × (P6 - P_i) (三维向量叉积)
      double jvx = zy * dz - zz * dy;
      double jvy = zz * dx - zx * dz;
      double jvz = zx * dy - zy * dx;

      // 填充雅可比矩阵的第 i 列
      jacobian[0][i] = jvx; // 沿基座 X 轴的线速度
      jacobian[1][i] = jvy; // 沿基座 Y 轴的线速度
      jacobian[2][i] = jvz; // 沿基座 Z 轴的线速度
      jacobian[3][i] = zx; // 绕基座 X 轴的角速度
      jacobian[4][i] = zy; // 绕基座 Y 轴的角速度
      jacobian[5][i] = zz; // 绕基座 Z 轴的角速度
    }

    return jacobian;
  }

  /// 计算 6x6 矩阵的行列式 (使用高斯消元法)
  /// 输入: 6x6 的二维数组
  /// 输出: 行列式的值
  static double _determinant6x6(List<List<double>> matrix) {
    int n = 6;
    // 深拷贝矩阵，避免修改原始雅可比矩阵数据
    List<List<double>> a = List.generate(n, (i) => List.from(matrix[i]));

    double det = 1.0;

    for (int i = 0; i < n; i++) {
      // 1. 寻找列主元 (Pivoting)，提高浮点数运算的数值稳定性
      int pivot = i;
      for (int j = i + 1; j < n; j++) {
        if (a[j][i].abs() > a[pivot][i].abs()) {
          pivot = j;
        }
      }

      // 如果主元极小，说明矩阵降秩，行列式为 0 (奇异状态)
      if (a[pivot][i].abs() < 1e-9) {
        return 0.0;
      }

      // 2. 交换当前行与主元行
      if (pivot != i) {
        List<double> temp = a[i];
        a[i] = a[pivot];
        a[pivot] = temp;
        det = -det; // 矩阵交换两行，行列式符号取反
      }

      det *= a[i][i];

      // 3. 消元操作：将当前列下方的所有元素化为 0
      for (int j = i + 1; j < n; j++) {
        double factor = a[j][i] / a[i][i];
        for (int k = i; k < n; k++) {
          a[j][k] -= factor * a[i][k];
        }
      }
    }

    return det;
  }

  /// 利用雅可比矩阵检测当前姿态的奇异度
  /// 输入: 6个关节的角度 List<double> jointsRad (单位: 弧度)
  /// 返回: Yoshikawa 操作度 (Manipulability w)。
  ///       当 w < 1e-4 时，通常可判定进入奇异区。
  static double getManipulability(List<double> jointsRad) {
    // 1. 获取当前姿态的 6x6 雅可比矩阵
    List<List<double>> jacobian = getJacobian(jointsRad);

    // 2. 计算行列式
    double det = _determinant6x6(jacobian);

    // 3. 返回操作度 (取绝对值)
    return det.abs();
  }

  // ----------- 内部轻量级矩阵运算工具 ----------- //
  static List<List<double>> _mdhMatrix(
    double alpha,
    double a,
    double d,
    double theta,
  ) {
    return [
      [cos(theta), -sin(theta), 0, a],
      [
        sin(theta) * cos(alpha),
        cos(theta) * cos(alpha),
        -sin(alpha),
        -d * sin(alpha),
      ],
      [
        sin(theta) * sin(alpha),
        cos(theta) * sin(alpha),
        cos(alpha),
        d * cos(alpha),
      ],
      [0.0, 0.0, 0.0, 1.0],
    ];
  }

  static List<List<double>> _multiply(
    List<List<double>> a,
    List<List<double>> b,
  ) {
    List<List<double>> result = List.generate(4, (_) => List.filled(4, 0.0));
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        for (int k = 0; k < 4; k++) {
          result[i][j] += a[i][k] * b[k][j];
        }
      }
    }
    return result;
  }

  // static double _toDeg(double rad) {
  //   return double.parse((rad * 180 / pi).toStringAsFixed(4));
  // }

  static double normalizeAngle(double angle) {
    double a = angle % (2 * pi);
    if (a > pi) a -= 2 * pi;
    if (a < -pi) a += 2 * pi;
    return a;
  }
}
