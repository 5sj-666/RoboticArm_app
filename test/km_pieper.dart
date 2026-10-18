import 'package:test/test.dart';
import 'package:robotic_arm_app/utils/km_pieper.dart';
import 'dart:math';

void main() {
  group('逆运动学测试', () {
    test('逆解函数应该包含有正解的角度[10, 20, 30, 40, 50, 60]', () {
      KinematicResult a = KmPieper.fk([10, 20, 30, 40, 50, 60]);

      List<List<double>> solutions = KmPieper.ik(a.transformation, null);
      List<double> inputDeg = [10, 20, 30, 40, 50, 60];
      List<double> inputRad = List.from(inputDeg.map((deg) => deg / 180 * pi));
      // inputRad[1] += pi / 2;
      // inputRad[2] -= pi / 2;

      print('输入的角度${inputDeg.toString()}');
      print('ik的结果:');
      solutions.forEach(
        (items) =>
            print(items.map((deg) => (deg * 180 / pi).toStringAsFixed(4))),
      );

      double tolerance = 0.001;
      // 检查 8 组解中是否有任意一组满足条件
      bool hasValidSolution = solutions.any(
        (sol) => isJointsClose(sol, inputRad, tolerance),
      );
      expect(hasValidSolution, isTrue, reason: '在 8 组逆解中没有找到符合误差范围的期望解');
    });

    // test('加法测试：2 加 3 应该等于 5', () {
    //   final result = calculator.add(2, 3);
    //   expect(result, 5); // 使用 expect 进行断言
    // });

    // test('减法测试：5 减 3 应该等于 2', () {
    //   final result = calculator.subtract(5, 3);
    //   expect(result, 2);
    // });
  });
}

/// actual输入给正解的角度列表。expected：逆解的某个结果输入。 tolerance： 允许的误差值
bool isJointsClose(
  List<double> actual,
  List<double> expected,
  double tolerance,
) {
  if (actual.length != expected.length) return false;
  for (int i = 0; i < actual.length; i++) {
    if ((actual[i] - expected[i]).abs() > tolerance) {
      return false;
    }
  }
  return true;
}
