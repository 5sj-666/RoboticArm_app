// import 'dart:ffi';
import 'package:flutter/material.dart';

class CubicBezierSelector extends StatefulWidget {
  // 对外暴露尺寸参数：支持固定宽高或自适应
  final double? width;
  final double? height;
  // 尺寸限制（可选）：避免尺寸过小或过大
  final double minWidth;
  final double minHeight;
  final double? maxWidth;
  final double? maxHeight;

  // 新增：实时回调（外部传入，组件内部参数变化时触发）
  final ValueChanged<String>? onPointsChanged;
  final String? initCubicBezier;
  final Color bg;
  final Color strokeColor;
  final Color startColor;
  final Color endColor;
  final Color cp1Color;
  final Color cp2Color;
  final Color helpColor;
  final Color bgGridColor;

  CubicBezierSelector({
    super.key,
    this.width,
    this.height,
    this.minWidth = 200, // 最小宽度默认200
    this.minHeight = 200, // 最小高度默认200
    this.maxWidth,
    this.maxHeight,
    this.onPointsChanged,
    this.initCubicBezier,
    this.bg = Colors.white,
    this.strokeColor = Colors.blue,
    this.startColor = Colors.blue,
    this.endColor = Colors.blue,
    this.cp1Color = Colors.lightGreen,
    this.cp2Color = Colors.lightGreen,
    this.helpColor = const Color.fromARGB(255, 220, 225, 228),
    this.bgGridColor = const Color.fromARGB(255, 236, 240, 242),
  });

  @override
  State<CubicBezierSelector> createState() => _CubicBezierSelectorState();
}

class _CubicBezierSelectorState extends State<CubicBezierSelector> {
  // 三次贝塞尔曲线的四个关键点（基于比例计算，适配动态尺寸）
  late Offset start;
  late Offset control1;
  late Offset control2;
  late Offset end;

  // 当前组件实际尺寸（动态更新）
  late Size _actualSize;

  // 当前拖拽的控制点（null表示未拖拽任何点）
  String? _draggingPoint;

  // 控制点半径（动态计算）
  late double _pointRadius;

  @override
  void initState() {
    super.initState();
    // 初始化默认尺寸
    _actualSize = Size(widget.width ?? 400, widget.height ?? 400);
    // 初始化点位置和控制点半径（无setState，仅初始化变量）
    _calcPoints(_actualSize);
    _pointRadius = _getPointRadius();

    // 初始化 贝塞尔函数
    if (widget.initCubicBezier != null) {
      initCP(widget.initCubicBezier!);
      print('widget.initCubicBezier ${widget.initCubicBezier}');
    }
  }

  @override
  void didUpdateWidget(covariant CubicBezierSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('didUpdateWidget');
    if (oldWidget.initCubicBezier != widget.initCubicBezier) {
      initCP(widget.initCubicBezier!);
    }
  }

  // 计算点位置（仅更新变量，不触发setState）
  void _calcPoints(Size size) {
    start = Offset(size.width * 0.1, size.height * 0.9); // 左侧12.5%，底部87.5%
    control1 = Offset(size.width * 0.3, size.height * 0.25); // 左侧30%，顶部25%
    control2 = Offset(size.width * 0.375, size.height * 0.25); // 左侧37.5%，顶部25%
    end = Offset(size.width * 0.9, size.height * 0.1); // 右侧87.5%，顶部12.5%
  }

  // 判断点击是否命中某个控制点（返回点的标识）
  String? _getTouchedPoint(Offset tapPos) {
    if ((tapPos - control1).distance < _pointRadius) return 'c1';
    if ((tapPos - control2).distance < _pointRadius) return 'c2';
    return null;
  }

  // 根据尺寸动态计算控制点半径（适配不同尺寸）
  double _getPointRadius() {
    return _actualSize.shortestSide * 0.05; // 取宽高中较小值的5%
  }

  // 根据当前尺寸计算拖拽限制范围（内边距为半径的1.5倍）
  double _getClampPadding() {
    return _pointRadius * 1.5;
  }

  // 处理尺寸变化（单独方法，通过setState触发重绘）
  void _handleSizeChange(Size newSize) {
    if (_actualSize == newSize) return; // 尺寸未变则不处理
    setState(() {
      _actualSize = newSize;
      _calcPoints(newSize); // 重新计算点位置
      _pointRadius = _getPointRadius(); // 重新计算控制点半径
    });
  }

  void callback() {
    if (widget.onPointsChanged != null) {
      print(
        'cp1: ${control1.dx}, ${control1.dy}, cp2: ${control2.dx}, ${control2.dy}, start: ${start.dx}, ${start.dy}, end: ${end.dx}, ${end.dy}',
      );
      // 计算得出三次贝塞尔曲线的控制点的x值， 在此需要减去画布的边距
      String getRealX(x) {
        return ((x - start.dx) / (end.dx - start.dx)).toStringAsFixed(3);
      }

      // 计算得出三次贝塞尔曲线的控制点的y值， 在此需要减去画布的边距，由于左下角是坐标（0，0），需要需要1-y
      String getRealY(y) {
        return (1.0 - (y - start.dx) / (start.dy - end.dy)).toStringAsFixed(3);
      }

      String cp1Dx = getRealX(control1.dx);
      String cp1Dy = getRealY(control1.dy);
      String cp2Dx = getRealX(control2.dx);
      String cp2Dy = getRealY(control2.dy);

      String str = '$cp1Dx, $cp1Dy, $cp2Dx, $cp2Dy';

      widget.onPointsChanged!(str);
    }
  }

  /// 初始化控制点 cubicBezier = ‘0.1，0.1，0.8，0.8’
  void initCP(String cubicBezier) {
    double w = _actualSize.width;
    double h = _actualSize.height;
    List<String> bezierList = cubicBezier.split(',');
    final Offset cp1 = Offset(
      double.parse(bezierList[0]) * w * 0.8 + w * 0.1,
      (1 - double.parse(bezierList[1])) * h * 0.8 + h * 0.1,
    );

    ///  h * 0.1是边距 h * 0.8是有效的画布大小，同理w
    final Offset cp2 = Offset(
      double.parse(bezierList[2]) * w * 0.8 + w * 0.1,
      (1 - double.parse(bezierList[3])) * h * 0.8 + h * 0.1,
    );

    print('$cp1, $cp2');
    control1 = cp1;
    control2 = cp2;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 用LayoutBuilder获取父容器约束，动态计算实际尺寸
        LayoutBuilder(
          builder: (context, constraints) {
            // 计算实际尺寸：优先使用外部传入的宽高，否则适配父容器约束
            final calculatedSize = Size(
              (widget.width ?? constraints.maxWidth).clamp(
                widget.minWidth,
                widget.maxWidth ?? double.infinity,
              ),
              (widget.height ?? constraints.maxHeight).clamp(
                widget.minHeight,
                widget.maxHeight ?? double.infinity,
              ),
            );

            // 尺寸变化时，通过单独方法触发setState（关键修复）
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleSizeChange(calculatedSize);
            });

            final clampPadding = _getClampPadding();

            return Container(
              width: calculatedSize.width,
              height: calculatedSize.height,
              decoration: BoxDecoration(color: widget.bg),
              child: GestureDetector(
                // 开始拖拽时判断是否命中控制点
                onPanStart: (details) {
                  final touched = _getTouchedPoint(details.localPosition);
                  if (touched != null) {
                    setState(() => _draggingPoint = touched);
                  }
                },
                // 拖拽过程中更新控制点位置（限制在合理范围内）
                onPanUpdate: (details) {
                  if (_draggingPoint == null) return;
                  setState(() {
                    final newDx = details.localPosition.dx.clamp(
                      clampPadding,
                      calculatedSize.width - clampPadding,
                    );
                    final newDy = details.localPosition.dy.clamp(
                      clampPadding,
                      calculatedSize.height - clampPadding,
                    );

                    if (_draggingPoint == 'c1') {
                      control1 = Offset(newDx, newDy);
                    } else if (_draggingPoint == 'c2') {
                      control2 = Offset(newDx, newDy);
                    }
                  });
                },
                // 结束拖拽
                onPanEnd: (details) {
                  setState(() => _draggingPoint = null);

                  callback();
                },
                child: SizedBox(
                  // decoration: BoxDecoration(border: Border.all()),
                  child: CustomPaint(
                    painter: CubicBezierPainter(
                      start: start,
                      control1: control1,
                      control2: control2,
                      end: end,
                      strokeColor: widget.strokeColor,
                      startColor: widget.startColor,
                      endColor: widget.endColor,
                      cp1Color: widget.cp1Color,
                      cp2Color: widget.cp2Color,
                      helpColor: widget.helpColor,
                      bgGridColor: widget.bgGridColor,
                      pointRadius: _pointRadius,
                    ),
                    size: calculatedSize,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// 绘制三次贝塞尔曲线的画笔（适配动态尺寸）
class CubicBezierPainter extends CustomPainter {
  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;
  final double pointRadius; // 控制点半径（动态传入）
  final Color strokeColor;
  final Color startColor;
  final Color endColor;
  final Color cp1Color;
  final Color cp2Color;
  final Color helpColor;
  final Color bgGridColor;

  CubicBezierPainter({
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
    required this.pointRadius,
    required this.strokeColor,
    required this.startColor,
    required this.endColor,
    required this.cp1Color,
    required this.cp2Color,
    required this.helpColor,
    required this.bgGridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 绘制辅助网格（便于观察坐标）
    _drawGrid(canvas, size);

    // 2. 绘制三次贝塞尔曲线
    final curvePaint = Paint()
      ..color = strokeColor
      ..strokeWidth =
          size.shortestSide *
          0.02 // 动态线宽
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(start.dx, start.dy) // 起点
      ..cubicTo(
        control1.dx,
        control1.dy, // 控制点1
        control2.dx,
        control2.dy, // 控制点2
        end.dx,
        end.dy, // 终点
      );
    canvas.drawPath(path, curvePaint);

    // 3. 绘制辅助线（连接起点-控制点1、控制点2-终点）
    final helperPaint = Paint()
      // ..color = Colors.grey[400]!
      ..color = helpColor
      ..strokeWidth =
          size.shortestSide *
          0.005 // 动态辅助线宽
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, control1, helperPaint);
    canvas.drawLine(control2, end, helperPaint);

    // 4. 绘制控制点和起点/终点（控制点在辅助线上方，避免遮挡）
    _drawControlPoint(canvas, start, startColor);
    _drawControlPoint(canvas, end, endColor);
    _drawControlPoint(canvas, control1, cp1Color);
    _drawControlPoint(canvas, control2, cp2Color);
  }

  // 绘制单个控制点（圆形，适配动态半径）
  void _drawControlPoint(Canvas canvas, Offset point, Color color) {
    // 控制点填充色
    canvas.drawCircle(point, pointRadius, Paint()..color = color);
    // 控制点边框
    canvas.drawCircle(
      point,
      pointRadius,
      Paint()
        ..color = Colors.white
        ..strokeWidth =
            pointRadius *
            0.2 // 边框宽度为半径的20%
        ..style = PaintingStyle.stroke,
    );
  }

  // 绘制网格背景（适配动态尺寸）
  void _drawGrid(canvas, Size size) {
    final gridPaint = Paint()
      // ..color = Colors.grey[200]!
      ..color = bgGridColor
      ..strokeWidth = 1;

    // 计算网格间距（适配不同尺寸）
    final gridSpacing = size.shortestSide * 0.1; // 取宽高中较小值的10%

    // 横线
    for (int i = 0; i <= size.height ~/ gridSpacing; i++) {
      canvas.drawLine(
        Offset(0, i * gridSpacing),
        Offset(size.width, i * gridSpacing),
        gridPaint,
      );
    }

    // 竖线
    for (int i = 0; i <= size.width ~/ gridSpacing; i++) {
      canvas.drawLine(
        Offset(i * gridSpacing, 0),
        Offset(i * gridSpacing, size.height),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CubicBezierPainter oldDelegate) {
    // 当任意点、尺寸或半径变化时重绘
    return start != oldDelegate.start ||
        control1 != oldDelegate.control1 ||
        control2 != oldDelegate.control2 ||
        end != oldDelegate.end ||
        pointRadius != oldDelegate.pointRadius;
  }
}
