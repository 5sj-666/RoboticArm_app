import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgCubicBezier extends StatelessWidget {
  final String timingFunc;
  final double? size;
  final Color color;
  final Color bg;

  SvgCubicBezier({
    super.key,
    required this.timingFunc,
    this.size = 20,
    this.color = Colors.black,
    this.bg = Colors.white,
  }) {
    // print(
    //   '--bezier color:  ${color.r * 255.toInt()}, ${color.g * 255.toInt()},${color.b * 255.toInt()}',
    // );
    // print('svg construc this.timingFunc$timingFunc');
  }

  final Map<String, String> preset = {
    "linear": "0,0,1,1",
    "ease-in": "0.42,0,1,1",
    "ease-out": "0,0,0.58,1",
    "ease-in-out": "0.42,0,0.58,1",
  };

  /// timingFunc '.2,.2,.8,.8' 要转为 ‘20 20,80 80’
  String timgFunc2Svg(timingFunc) {
    // print('---svg timgfunc2svg: $timingFunc');

    // 1. 分割字符串为小数列表（移除首尾可能的点或空格）
    List<String> parts = (preset[timingFunc] ?? timingFunc).trim().split(',');
    // 2. 转换为数值并乘以100取整
    List<int> values = parts.map((part) {
      double value = double.parse(part.trim()); // 解析为小数
      return (value * 100).toInt(); // 乘以100并取整
    }).toList();
    String ctrolPointString =
        '${values[0]} ${100 - values[1]},${values[2]} ${100 - values[3]}';
    // print('ctrolPointString: $ctrolPointString');

    return '''
      <svg width="100" height="100" viewBox="0 0 100 100">
      <path
        d="M 0 100 C $ctrolPointString,100 0"
        stroke-width="5"
         stroke="rgb(${(color.r * 255).toInt()}, ${(color.g * 255).toInt()},${(color.b * 255).toInt()})"
        fill="transparent"
      />
    </svg>''';
  }

  @override
  Widget build(BuildContext context) {
    final String svgStr = timgFunc2Svg(timingFunc);
    return Container(
      padding: EdgeInsets.all(10),
      // color: Color.fromARGB(255, 232, 147, 51),
      decoration: BoxDecoration(
        color: bg,
        border: BoxBorder.all(width: 0.5),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: SvgPicture.string(
        svgStr,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
