import 'package:flutter/material.dart';
import 'package:robotic_arm_app/utils/motorCmd.dart';
import 'package:robotic_arm_app/cubit/joints_cubit.dart';
import 'package:robotic_arm_app/cubit/motions_cubit.dart';
import 'package:robotic_arm_app/cubit/ble_cubit.dart';
import 'package:robotic_arm_app/pages/devices/motor/motorLogCubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:robotic_arm_app/components/joint_slider.dart';

class SlidingPanelContent extends StatelessWidget {
  final JointsCubit jointsCubit;
  final MotionsCubit motionsCubit;
  final BleCubit bleCubit;
  final MotorLogCubit motorLogCubit;

  SlidingPanelContent({
    Key? key,
    required this.jointsCubit,
    required this.motionsCubit,
    required this.bleCubit,
    required this.motorLogCubit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void _updateJointValue(double newVal, int index) {
      print('_updateJointValue: newval: $newVal ,index$index');

      Future.delayed(const Duration(seconds: 0), () {
        jointsCubit.setSingleJoint('joint${index + 1}', newVal);
        print('Information Page 关节$index: ${jointsCubit.state}');
      });
    }

    void _updateJointEnd(double newVal, int index) {
      print('---关节变化结束---$newVal --- $index');
      int motorId = 21 + index;

      /// 将速度指令和位置指令发送给单片机
      final motorCmd = MotorCmdGenerator();
      final enableCmd = motorCmd.generateCMD('enable', {'motorId': motorId});
      bleCubit.sendSingleCmd(enableCmd);
      // motorLogCubit.addLog(cmd: enableCmd);

      final runmodeCmd = motorCmd.generateCMD('run_mode', {
        'motorId': motorId,
        'run_mode': 1,
      });
      bleCubit.sendSingleCmd(runmodeCmd);
      // motorLogCubit.addLog(cmd: runmodeCmd);

      final speedCmd = motorCmd.generateCMD('limit_spd', {
        'motorId': motorId,
        'limit_spd': 2.0,
      });
      bleCubit.sendSingleCmd(speedCmd);
      // motorLogCubit.addLog(cmd: speedCmd);

      // 第二个关节旋转方向与3D模型相反，所以位置取反
      if (motorId == 22) {
        newVal = -newVal;
      }

      final locationCmd = motorCmd.generateCMD('loc_ref', {
        'motorId': motorId,
        'loc_ref': newVal / 180 * 3.14,
      });
      bleCubit.sendSingleCmd(locationCmd);
      // motorLogCubit.addLog(cmd: locationCmd);
    }

    return BlocBuilder<JointsCubit, JointsState>(
      builder: (context, state) {
        return SizedBox(
          height: 220,
          child: Wrap(
            children: [
              // 等待优化
              FractionallySizedBox(
                widthFactor: 0.5,
                child: JointSlider(
                  title: '关节1:',
                  value: state.joint1,
                  onValueChanged: _updateJointValue,
                  index: 0,
                  min: -180.0,
                  max: 180.0,
                  onChangeEnd: _updateJointEnd,
                  disable: motionsCubit.state.status != MotionStatus.idle,
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.5,
                child: JointSlider(
                  title: '关节2:',
                  // value: _jointValues[i],
                  value: state.joint2,
                  onValueChanged: _updateJointValue,
                  index: 1,
                  // min: -90.0,
                  // max: 90.0,
                  min: -180.0,
                  max: 180.0,
                  onChangeEnd: _updateJointEnd,
                  disable: motionsCubit.state.status != MotionStatus.idle,
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.5,
                child: JointSlider(
                  title: '关节3:',
                  value: state.joint3,
                  onValueChanged: _updateJointValue,
                  index: 2,
                  min: -180.0,
                  max: 180.0,
                  onChangeEnd: _updateJointEnd,
                  disable: motionsCubit.state.status != MotionStatus.idle,
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.5,
                child: JointSlider(
                  title: '关节4:',
                  value: state.joint4,
                  onValueChanged: _updateJointValue,
                  index: 3,
                  min: -180.0,
                  max: 180.0,
                  onChangeEnd: _updateJointEnd,
                  disable: motionsCubit.state.status != MotionStatus.idle,
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.5,
                child: JointSlider(
                  title: '关节5:',
                  value: state.joint5,
                  onValueChanged: _updateJointValue,
                  index: 4,
                  min: -180.0,
                  max: 180.0,
                  onChangeEnd: _updateJointEnd,
                  disable: motionsCubit.state.status != MotionStatus.idle,
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.5,
                child: JointSlider(
                  title: '关节6:',
                  value: state.joint6,
                  onValueChanged: _updateJointValue,
                  index: 5,
                  min: -180.0,
                  max: 180.0,
                  onChangeEnd: _updateJointEnd,
                  disable: motionsCubit.state.status != MotionStatus.idle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
