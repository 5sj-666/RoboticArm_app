import 'package:flutter/material.dart';
// import 'dart:async';
// import 'dart:math' as math;
// import 'package:three_js/three_js.dart' as three;
// import 'package:three_js_helpers/three_js_helpers.dart';
// import 'package:flutter/services.dart';
import 'devices/arm.dart'; // 引入机械臂页面
import 'devices/information.dart'; // 引入设备信息页面

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // threeJs 3D 画面
          // Positioned.fill(child: threeJs.build()),
          ArmPage(),
          DeviceInformationPage(),
          // 底部信息块
          // Positioned(
          //   left: 0,
          //   // right: 0,
          //   bottom: -400,
          //   child: DeviceInformationPage(),
          //   // child: Card(
          //   //   color: Colors.white.withOpacity(0.9),
          //   //   elevation: 8,
          //   //   shape: RoundedRectangleBorder(
          //   //       borderRadius: BorderRadius.circular(12)),
          //   //   child: Padding(
          //   //     padding: const EdgeInsets.all(16.0),
          //   //     child: Column(
          //   //       mainAxisSize: MainAxisSize.min,
          //   //       children: [
          //   //         Text(
          //   //           '设备信息',
          //   //           style:
          //   //               TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          //   //         ),
          //   //         SizedBox(height: 8),
          //   //         Text('这里可以展示设备状态、连接信息等内容。'),
          //   //       ],
          //   //     ),
          //   //   ),
          //   // ),
          // ),
        ],
      ),
    );
  }
}
