
import 'dart:math';

// /**
//  * 三次贝塞尔曲线中，根据x坐标计算对应的y坐标
//  * @param {number} xTarget - 目标x坐标
//  * @param {Array} p1 - 第二个控制点 [x, y]
//  * @param {Array} p2 - 第三个控制点 [x, y]
//  * @param {number} epsilon - 精度控制，默认1e-6
//  * @param {number} maxIter - 最大迭代次数，默认100
//  * @returns {number|null} 对应的y坐标，如果求解失败返回null
//  */
// function bezierXToY(xTarget, p1, p2, epsilon = 1e-6, maxIter = 100) {
//   const [x0, y0] = [0, 0];
//   const [x1, y1] = p1;
//   const [x2, y2] = p2;
//   const [x3, y3] = [1, 1];

//   // 计算x分量
//   function bezierX(t) {
//     return (
//       x0 * Math.pow(1 - t, 3) +
//       3 * x1 * Math.pow(1 - t, 2) * t +
//       3 * x2 * (1 - t) * Math.pow(t, 2) +
//       x3 * Math.pow(t, 3)
//     );
//   }

//   // x分量的导数
//   function derivativeX(t) {
//     return (
//       3 * Math.pow(1 - t, 2) * (x1 - x0) +
//       6 * (1 - t) * t * (x2 - x1) +
//       3 * Math.pow(t, 2) * (x3 - x2)
//     );
//   }

//   // 检查x是否在有效范围内
//   const xStart = bezierX(0);
//   const xEnd = bezierX(1);
//   const xMin = Math.min(xStart, xEnd);
//   const xMax = Math.max(xStart, xEnd);

//   if (xTarget < xMin - epsilon || xTarget > xMax + epsilon) {
//     return null;
//   }

//   // 牛顿迭代求解t
//   let t = 0.5;
//   for (let i = 0; i < maxIter; i++) {
//     const xCurrent = bezierX(t);
//     if (Math.abs(xCurrent - xTarget) < epsilon) break;

//     const dx = derivativeX(t);
//     if (Math.abs(dx) < 1e-12) {
//       // 导数接近0时使用二分法
//       let low = 0,
//         high = 1;
//       for (let j = 0; j < 50; j++) {
//         const mid = (low + high) / 2;
//         if (bezierX(mid) < xTarget) low = mid;
//         else high = mid;
//         if (high - low < epsilon) {
//           t = (low + high) / 2;
//           break;
//         }
//       }
//       break;
//     }

//     t -= (xCurrent - xTarget) / dx;
//     t = Math.max(0, Math.min(1, t));
//   }

//   // 计算对应的y值
//   return (
//     y0 * Math.pow(1 - t, 3) +
//     3 * y1 * Math.pow(1 - t, 2) * t +
//     3 * y2 * (1 - t) * Math.pow(t, 2) +
//     y3 * Math.pow(t, 3)
//   );
// }
/// 三次贝塞尔曲线中，根据x坐标计算对应的y坐标
/// [xTarget] - 目标x坐标, x表示时间
/// [p1] - 第二个控制点 [x, y]
/// [p2] - 第三个控制点 [x, y]
/// [epsilon] - 精度控制，默认1e-6
/// [maxIter] - 最大迭代次数，默认100
/// 返回对应的y坐标，如果求解失败返回null
double bezierXToY(
  double xTarget,
  List<double> p1,
  List<double> p2, {
  double epsilon = 1e-6,
  int maxIter = 100,
}) {
  // 贝塞尔曲线控制点（固定起点(0,0)和终点(1,1)）
  const x0 = 0.0, y0 = 0.0;
  final x1 = p1[0], y1 = p1[1];
  final x2 = p2[0], y2 = p2[1];
  const x3 = 1.0, y3 = 1.0;

  // 计算t对应的x分量
  double bezierX(double t) {
    return x0 * _pow(1 - t, 3) +
        3 * x1 * _pow(1 - t, 2) * t +
        3 * x2 * (1 - t) * _pow(t, 2) +
        x3 * _pow(t, 3);
  }

  // x分量的导数（用于牛顿迭代）
  double derivativeX(double t) {
    return 3 * _pow(1 - t, 2) * (x1 - x0) +
        6 * (1 - t) * t * (x2 - x1) +
        3 * _pow(t, 2) * (x3 - x2);
  }

  // 检查目标x是否在有效范围内
  final xStart = bezierX(0);
  final xEnd = bezierX(1);
  final xMin = xStart < xEnd ? xStart : xEnd;
  final xMax = xStart > xEnd ? xStart : xEnd;

  if (xTarget < xMin - epsilon || xTarget > xMax + epsilon) {
    return xTarget;
  }

  // 牛顿迭代法求解t值
  double t = 0.5;
  for (int i = 0; i < maxIter; i++) {
    final xCurrent = bezierX(t);
    if ((xCurrent - xTarget).abs() < epsilon) {
      break;
    }

    final dx = derivativeX(t);
    if (dx.abs() < 1e-12) {
      // 导数接近0时切换为二分法
      double low = 0.0, high = 1.0;
      for (int j = 0; j < 50; j++) {
        final mid = (low + high) / 2;
        if (bezierX(mid) < xTarget) {
          low = mid;
        } else {
          high = mid;
        }
        if (high - low < epsilon) {
          t = (low + high) / 2;
          break;
        }
      }
      break;
    }

    // 牛顿迭代公式
    t -= (xCurrent - xTarget) / dx;
    // 确保t在[0,1]范围内
    t = t.clamp(0.0, 1.0);
  }

  // 根据求解得到的t计算对应的y值
  return y0 * _pow(1 - t, 3) +
      3 * y1 * _pow(1 - t, 2) * t +
      3 * y2 * (1 - t) * _pow(t, 2) +
      y3 * _pow(t, 3);
}

// 封装幂运算（处理小数次方更方便）
double _pow(double base, int exponent) {
  double result = 1.0;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}



/// 三次贝塞尔曲线（范围 0-1）：根据 x 坐标计算对应的 y 坐标
/// [x] - 目标 x 坐标（需在 0-1 范围内，超出返回 null）
/// [controlPoint1] - 第一个控制点（格式：[x, y]，x/y 均在 0-1 内）
/// [controlPoint2] - 第二个控制点（格式：[x, y]，x/y 均在 0-1 内）
/// [epsilon] - 计算精度（默认 1e-6，越小越精确但耗时略长）
/// [maxIter] - 最大迭代次数（默认 100，确保计算不卡死）
/// 返回：对应的 y 坐标（0-1 范围内），失败返回 null
double? calculateBezierY(
  double x, {
  required List<double> controlPoint1,
  required List<double> controlPoint2,
  double epsilon = 1e-6,
  int maxIter = 100,
}) {
  // 1. 校验参数合法性（避免无效输入）
  if (x < 0 || x > 1) {
    // debugPrint("错误：x 坐标必须在 0-1 范围内");
    return null;
  }
  if (controlPoint1.length != 2 || controlPoint2.length != 2) {
    // debugPrint("错误：控制点必须是长度为 2 的数组（[x, y]）");
    return null;
  }
  final p1x = controlPoint1[0], p1y = controlPoint1[1];
  final p2x = controlPoint2[0], p2y = controlPoint2[1];
  if ((p1x < 0 || p1x > 1) || (p1y < 0 || p1y > 1) || 
      (p2x < 0 || p2x > 1) || (p2y < 0 || p2y > 1)) {
    // debugPrint("错误：控制点的 x/y 必须在 0-1 范围内");
    return null;
  }

  // 2. 贝塞尔曲线固定起点(0,0)、终点(1,1)
  const x0 = 0.0, y0 = 0.0;
  const x3 = 1.0, y3 = 1.0;

  // 3. 计算 t 对应的 x 坐标（三次贝塞尔公式）
  double _bezierX(double t) {
    return x0 * pow(1 - t, 3) +
        3 * p1x * pow(1 - t, 2) * t +
        3 * p2x * (1 - t) * pow(t, 2) +
        x3 * pow(t, 3);
  }

  // 4. x 分量的导数（用于牛顿迭代法加速求解）
  double _derivativeX(double t) {
    return 3 * pow(1 - t, 2) * (p1x - x0) +
        6 * (1 - t) * t * (p2x - p1x) +
        3 * pow(t, 2) * (x3 - p2x);
  }

  // 5. 牛顿迭代法求解 t 值（核心逻辑）
  double t = 0.5; // 初始猜测值（0.5 中间位置）
  for (int i = 0; i < maxIter; i++) {
    final currentX = _bezierX(t);
    final diff = currentX - x;

    // 达到精度要求，停止迭代
    if (diff.abs() < epsilon) break;

    // 导数接近 0 时，切换二分法（避免除以 0 或迭代发散）
    final dx = _derivativeX(t);
    if (dx.abs() < 1e-12) {
      double low = 0.0, high = 1.0;
      for (int j = 0; j < 50; j++) {
        final mid = (low + high) / 2;
        if (_bezierX(mid) < x) {
          low = mid;
        } else {
          high = mid;
        }
        if (high - low < epsilon) {
          t = (low + high) / 2;
          break;
        }
      }
      break;
    }

    // 牛顿迭代公式：t = t - (f(t) - target)/f'(t)
    t -= diff / dx;
    t = t.clamp(0.0, 1.0); // 确保 t 始终在 0-1 范围内
  }

  // 6. 根据求解出的 t，计算对应的 y 坐标（三次贝塞尔公式）
  final y = y0 * pow(1 - t, 3) +
      3 * p1y * pow(1 - t, 2) * t +
      3 * p2y * (1 - t) * pow(t, 2) +
      y3 * pow(t, 3);

  // 确保 y 在 0-1 范围内（避免精度误差导致超出）
  return y.clamp(0.0, 1.0);
}
