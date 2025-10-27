// import 'package:flutter/material.dart';
// import 'package:auto_route/auto_route.dart';
// import 'package:robotic_arm_app/components/MotionNode.dart';
// import 'package:robotic_arm_app/types/motions.dart';

// @RoutePage()
// class OrderKeyframePage extends StatefulWidget {
//   const OrderKeyframePage({super.key});

//   @override
//   State<OrderKeyframePage> createState() => _orderKeyframe();
// }

// // ignore: camel_case_types
// class _orderKeyframe extends State<OrderKeyframePage> {
//   // Color _targetColor = Colors.grey;

//   // Offset positions = List<Offset>()
//   List<Offset> _positions = [Offset(50, 75), Offset(200, 75), Offset(350, 75)];
//   final Size _widgetSize = Size(100, 150);

//   // final List<Keyframe> _nodes = [
//   //   Keyframes(name: 'joint1', motorId: 21, keyframe: []),
//   //   Keyframes(name: 'joint2', motorId: 22, keyframe: []),
//   //   Keyframes(name: 'joint3', motorId: 23, keyframe: []),
//   // ];

//   @override
//   Widget build(BuildContext context) {
//     // 获取屏幕尺寸（用于限制拖拽范围）
//     final screenSize = MediaQuery.of(context).size;

//     Offset dragUpdate(details, Size screenSize, Size widgetSize, index) {
//       // return
//       // setState(() {});
//       // 计算新位置（累加拖拽偏移量）
//       double newX = _positions[index].dx + details.delta.dx;
//       double newY = _positions[index].dy + details.delta.dy;

//       // 限制组件不能拖出屏幕（可选）
//       // 左边界：组件右边缘不小于0
//       newX = newX.clamp(
//         0, // 最小X（左边界）
//         screenSize.width - widgetSize.width, // 最大X（右边界）
//       );
//       // 上边界：组件下边缘不小于0
//       newY = newY.clamp(
//         0, // 最小Y（上边界）
//         screenSize.height - widgetSize.height - 120, // 最大Y（下边界）
//       );

//       // 更新位置
//       return Offset(newX, newY);
//       // return Offset(0, 0);
//     }

//     return Scaffold(
//         appBar: AppBar(
//           title: Text('关键帧排序'),
//         ),
//         body: Container(
//           width: double.infinity,
//           height: double.infinity,
//           decoration: BoxDecoration(
//             color: Colors.grey.shade100,
//             // border: BoxBorder.all(color: Colors.yellow, width: 2),
//             // borderRadius: BorderRadius.circular(8),
//             // border: Border.all(color: Colors.black54),
//             // image: DecorationImage(
//             //   image: NetworkImage("https://picsum.photos/1000/800"),
//             //   repeat: ImageRepeat.repeat,
//             //   // fit: BoxFit.cover,
//             // ),
//           ),
//           child: Stack(
//             children: [
//               CustomPaint(
//                 size: screenSize, // 画布大小为屏幕尺寸
//                 painter: LinePainter(
//                     start: Offset(_positions[0].dx + _widgetSize.width / 2,
//                         _positions[0].dy + _widgetSize.height / 2), // 块A的中心
//                     end: Offset(_positions[1].dx + _widgetSize.width / 2,
//                         _positions[1].dy + _widgetSize.height / 2) // 块B的中心
//                     ),
//               ),
//               // for (int i = 0; i < _nodes.length; i++)
//               //   Positioned(
//               //       left: _positions[i].dx,
//               //       top: _positions[i].dy,
//               //       child: GestureDetector(
//               //         onPanUpdate: (details) {
//               //           setState(() {
//               //             Offset position =
//               //                 dragUpdate(details, screenSize, _widgetSize, i);
//               //             _positions[i] = position;
//               //           });
//               //         },
//               //         child: MotionNode(),
//               //       )
//               //       // MotionNode(),
//               //       ),

//               // Positioned(
//               //     left: _positions[0].dx,
//               //     top: _positions[0].dy,
//               //     child: GestureDetector(
//               //       onPanUpdate: (details) {
//               //         final position =
//               //             dragUpdate(details, screenSize, _widgetSize, 0);
//               //         setState(() {
//               //           _positions[0] = position;
//               //         });
//               //       },
//               //       child: MotionNode(),
//               //     )
//               //     // MotionNode(),
//               //     ),
//             ],
//           ),
//         ));
//   }
// }

// // 自定义画笔：绘制连接线
// class LinePainter extends CustomPainter {
//   final Offset start; // 起点
//   final Offset end; // 终点

//   LinePainter({required this.start, required this.end});

//   @override
//   void paint(Canvas canvas, Size size) {
//     // 定义线条属性
//     final paint = Paint()
//       ..color = Colors.grey[600]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1
//       ..strokeCap = StrokeCap.round; // 线条端点为圆角

//     // 绘制直线
//     // canvas.drawLine(start, end, paint);

//     // 可选：绘制曲线（更美观）
//     final path = Path()
//       ..moveTo(start.dx, start.dy)
//       ..quadraticBezierTo(
//         (start.dx + end.dx) / 2, // 控制点X
//         start.dy, // 控制点Y（可调整为中间高度）
//         end.dx, end.dy,
//       );
//     canvas.drawPath(path, paint);
//   }

//   // 当起点或终点变化时，触发重绘
//   @override
//   bool shouldRepaint(covariant LinePainter oldDelegate) {
//     return start != oldDelegate.start || end != oldDelegate.end;
//   }
// }
