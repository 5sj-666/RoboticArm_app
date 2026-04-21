import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'dart:async';
// import 'dart:math' as math;
// import 'package:three_js/three_js.dart' as three;
// import 'package:three_js_helpers/three_js_helpers.dart';
// import 'package:flutter/services.dart';
import 'arm.dart'; // 引入机械臂页面
import 'information.dart'; // 引入设备信息页面
import 'package:robotic_arm_app/cubit/ik_cubit.dart';
import 'package:three_js_transform_controls/transform_controls_gizmo.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    IKCubit ikCubit = BlocProvider.of<IKCubit>(context);

    return Scaffold(
      body: Stack(
        children: [
          ArmPage(),
          DeviceInformationPage(),

          BlocBuilder<IKCubit, IKState>(
            builder: (buildContext, ikState) {
              return Positioned(
                top: 20,
                left: 0,
                child: FilledButton(
                  onPressed: () {
                    if (ikCubit.state.dragPose.mode == GizmoType.translate) {
                      ikCubit.setMode(GizmoType.rotate);
                    } else {
                      ikCubit.setMode(GizmoType.translate);
                    }
                  },
                  child: Text(
                    ikCubit.state.dragPose.mode == GizmoType.translate
                        ? "移动"
                        : "旋转",
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
