import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 回调改为：带 String 参数
typedef StringCallback = void Function(String value, String id);

Future<void> showLongPressConfirmPopover({
  required BuildContext context,
  required Offset touchPoint, // 用户点击的坐标
  required StringCallback onConfirm,
  required String name,
  required String id,
  String message = '确定删除该动作吗 ?',
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'popover',
    barrierColor: Colors.black12,
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (ctx, a1, a2) {
      // --------------------------
      // 智能计算位置：箭头永远指向点击点，距离10px
      // --------------------------
      const double arrowToTouchDistance = 10; // 箭头离点击点 10px
      const double arrowWidth = 12;
      const double arrowHeight = 6;
      const double panelWidth = 200;
      const double panelRadius = 2;

      // 弹框默认出现在点击点 右下 方向
      double panelLeft = touchPoint.dx + arrowToTouchDistance;
      double panelTop = touchPoint.dy + arrowToTouchDistance;

      // // 箭头坐标：永远指向 touchPoint
      // double arrowLeft = touchPoint.dx;
      // double arrowTop = touchPoint.dy;

      return Stack(
        children: [
          // 点击点：直径3白点 + 直径5光晕
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true, // 关键：点击可以穿透！
              child: CustomPaint(painter: _DotHaloPainter(center: touchPoint)),
            ),
          ),
          Positioned(
            left: panelLeft,
            top: panelTop,
            child: // 箭头：SVG 三角形，精准指向点击圆点
            Transform.translate(
              offset: Offset(
                // 箭头水平居中指向点击点
                touchPoint.dx - panelLeft - (arrowWidth / 2),
                // 箭头距离点击点 10px
                -arrowHeight + 10,
              ),
              child: SvgPicture.string(
                '''
                    <svg width="12" height="6" viewBox="0 0 12 6">
                      <path d="M0 6 L6 0 L12 6 Z" fill="#ffffff" />
                    </svg>
                    ''',
                width: arrowWidth,
                height: arrowHeight,
              ),
            ),
          ),

          // 弹框 + 智能指向箭头
          Positioned(
            left: (panelLeft - 20).clamp(
              0,
              MediaQuery.of(context).size.width - panelWidth - 10,
            ),
            top: panelTop + 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: panelWidth,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(panelRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              '取消',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              onConfirm(name, id);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              '确认',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

// 圆点光晕：直径3白点 + 直径5柔和光晕
class _DotHaloPainter extends CustomPainter {
  final Offset center;

  _DotHaloPainter({required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    // 光晕直径 5（半径 2.5）
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0.5),
        ],
        stops: const [0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 2.5));
    canvas.drawCircle(center, 12, haloPaint);

    // 中心白点直径 3（半径 1.5）
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _DotHaloPainter oldDelegate) {
    return oldDelegate.center != center;
  }
}
