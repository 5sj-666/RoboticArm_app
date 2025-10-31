import 'package:flutter/material.dart';
// import 'dart:async';
// import 'dart:math' as math;
// import 'package:three_js/three_js.dart' as three;
// import 'package:three_js_helpers/three_js_helpers.dart';
// import 'package:flutter/services.dart';
import '../devices/arm.dart'; // 引入机械臂页面
import '../devices/information.dart'; // 引入设备信息页面

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ArmPage(),
          DeviceInformationPage(),
        ],
      ),
    );
  }
}
