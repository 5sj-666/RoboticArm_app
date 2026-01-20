import 'package:flutter/material.dart';
import 'package:robotic_arm_app/utils/motorCmd.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'dart:convert';
import 'package:robotic_arm_app/cubit/joints_cubit.dart';
import 'package:robotic_arm_app/cubit/motions_cubit.dart';
import 'package:robotic_arm_app/cubit/ble_cubit.dart';
import 'package:robotic_arm_app/pages/devices/motor/motorLogCubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:robotic_arm_app/components/joint_slider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:robotic_arm_app/utils/sharedPreferences.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'package:intl/intl.dart';
// import 'dart:ui' as ui;
// import 'package:robotic_arm_app/pages/devices/bleDevices.dart';
// import 'package:robotic_arm_app/pages/devices/motor/motorLog.dart';
import 'package:robotic_arm_app/components/MotionStatusBtn.dart';
import 'package:robotic_arm_app/pages/devices/sliding_collapse.dart';

class DeviceInformationPage extends StatefulWidget {
  const DeviceInformationPage({super.key});

  @override
  State<DeviceInformationPage> createState() => _deviceInformationPage();
}

// ignore: camel_case_types
class _deviceInformationPage extends State<DeviceInformationPage> {
  late JointsCubit jointsCubit;
  late MotionsCubit motionsCubit;
  late BleCubit bleCubit;
  late MotorLogCubit motorLogCubit;

  void _updateJointValue(double newVal, int index) {
    print('_updateJointValue: newval: $newVal ,index$index');

    Future.delayed(const Duration(seconds: 0), () {
      jointsCubit.setSingleJoint('joint${index + 1}', newVal);
      print('Information Page 关节$index: ${jointsCubit.state}');
    });
  }

  void _updateJointEnd(double newVal, int index) {
    print('---关节变化结束---$newVal --- $index');

    /// 将速度指令和位置指令发送给单片机
    final motorCmd = MotorCmdGenerator();
    final enableCmd = motorCmd.generateCMD('enable', {'motorId': 21});
    bleCubit.sendSingleCmd(enableCmd);
    motorLogCubit.addLog(cmd: enableCmd);

    int motorId = 21 + index;

    final runmodeCmd = motorCmd.generateCMD('run_mode', {
      'motorId': motorId,
      'run_mode': 1,
    });
    bleCubit.sendSingleCmd(runmodeCmd);
    motorLogCubit.addLog(cmd: runmodeCmd);

    final speedCmd = motorCmd.generateCMD('limit_spd', {
      'motorId': motorId,
      'limit_spd': 2.0,
    });
    bleCubit.sendSingleCmd(speedCmd);
    motorLogCubit.addLog(cmd: speedCmd);

    final locationCmd = motorCmd.generateCMD('loc_ref', {
      'motorId': motorId,
      'loc_ref': newVal / 180 * 3.14,
    });
    bleCubit.sendSingleCmd(locationCmd);
    motorLogCubit.addLog(cmd: locationCmd);
  }

  @override
  void initState() {
    super.initState();
    // ignore: no_leading_underscores_for_local_identifiers
    // _scrollController = ScrollController();

    // initialize motionsCubit before reading its state
    motionsCubit = BlocProvider.of<MotionsCubit>(context);
    bleCubit = BlocProvider.of<BleCubit>(context);
    bleCubit.init();
    motorLogCubit = BlocProvider.of<MotorLogCubit>(context);
  }

  @override
  void dispose() {
    // _scrollController.dispose();
    // _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    jointsCubit = BlocProvider.of<JointsCubit>(context);

    PanelController _pc = PanelController();

    return SlidingUpPanel(
      // color: Colors.black,
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      // 面板关闭时显示的高度
      minHeight: 80,
      // 面板打开时显示的高度
      maxHeight: 300,
      backdropEnabled: false,
      panelSnapping: true, //自动吸附效果
      onPanelSlide: (position) {},
      controller: _pc,

      // 面板内容
      // panel:
      panelBuilder: (sc) => BlocBuilder<MotionsCubit, MotionsState>(
        builder: (context, motionState) {
          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView(
              // mainAxisAlignment: MainAxisAlignment.start,
              controller: sc,
              children: <Widget>[
                SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 30,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                    ),
                  ],
                ),
                slidingCollapse(bleCubit),
                SizedBox(height: 14.0),
                BlocBuilder<JointsCubit, JointsState>(
                  builder: (context, state) {
                    return Wrap(
                      children: [
                        // 等待优化
                        FractionallySizedBox(
                          widthFactor: 0.5,
                          child: JointSlider(
                            title: '关节1:',
                            value: state.joint1,
                            onValueChanged: _updateJointValue,
                            index: 0,
                            min: -145.0,
                            max: 145.0,
                            onChangeEnd: _updateJointEnd,
                            disable:
                                motionsCubit.state.status != MotionStatus.idle,
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
                            min: -100.0,
                            max: 100.0,
                            onChangeEnd: _updateJointEnd,
                            disable:
                                motionsCubit.state.status != MotionStatus.idle,
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.5,
                          child: JointSlider(
                            title: '关节3:',
                            value: state.joint3,
                            onValueChanged: _updateJointValue,
                            index: 2,
                            min: -145.0,
                            max: 145.0,
                            onChangeEnd: _updateJointEnd,
                            disable:
                                motionsCubit.state.status != MotionStatus.idle,
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.5,
                          child: JointSlider(
                            title: '关节4:',
                            value: state.joint4,
                            onValueChanged: _updateJointValue,
                            index: 3,
                            min: -145.0,
                            max: 145.0,
                            onChangeEnd: _updateJointEnd,
                            disable:
                                motionsCubit.state.status != MotionStatus.idle,
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.5,
                          child: JointSlider(
                            title: '关节5:',
                            value: state.joint5,
                            onValueChanged: _updateJointValue,
                            index: 4,
                            min: -145.0,
                            max: 145.0,
                            onChangeEnd: _updateJointEnd,
                            disable:
                                motionsCubit.state.status != MotionStatus.idle,
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.5,
                          child: JointSlider(
                            title: '关节6:',
                            value: state.joint6,
                            onValueChanged: _updateJointValue,
                            index: 5,
                            min: -145.0,
                            max: 145.0,
                            onChangeEnd: _updateJointEnd,
                            disable:
                                motionsCubit.state.status != MotionStatus.idle,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20),
                if (motionsCubit.state.status == MotionStatus.idle)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      FilledButton(
                        onPressed: () {
                          context.router.push(NamedRoute('OrderKeyframeRoute'));
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll<Color>(
                            Colors.blue.shade300,
                          ),
                        ),
                        child: const Text(
                          '设计动作',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          print('保存为关键帧');
                          saveDialog(
                            context: context,
                            jointsCubit: jointsCubit,
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll<Color>(
                            Colors.blue.shade300,
                          ),
                        ),
                        child: const Text(
                          '保存为关键帧',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                if (motionsCubit.state.status == MotionStatus.idle)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(onPressed: () {}, child: Text('使能')),
                      ElevatedButton(
                        onPressed: () {
                          // for (int i = 0; i < 6; i++) {}
                          motionsCubit.updateStatus(MotionStatus.goToZero);
                          print('归零');
                        },
                        child: Text('归零'),
                      ),
                    ],
                  ),
                if (motionsCubit.state.status != MotionStatus.idle)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      MotionStatusBtn(),
                      ElevatedButton(
                        onPressed: () {
                          motionsCubit.clearCurMotion();
                          print('--卸载动作---${motionsCubit.state.currentMotion}');
                          // motionsCubit.state.status
                        },
                        child: Text('卸载动作'),
                      ),
                      // ElevatedButton(onPressed: () {}, child: Text('卸载动作')),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> saveDialog({
  required BuildContext context,
  required JointsCubit jointsCubit,
}) async {
  final _keyframeNameCtrl = TextEditingController();

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('关键帧名称', style: TextStyle(fontSize: 16)),
        content: TextField(controller: _keyframeNameCtrl, autofocus: true),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final saveName = _keyframeNameCtrl.text;
              Keyframe keyframe = generateKeyframe(jointsCubit.state, saveName);
              final keyframeJson = json.encode(keyframe.toJson());
              print(
                '保存关键帧keyframeName: $saveName,  keyframe.toJson: $keyframeJson',
              );

              await SharedPrefsStorage.save(
                key: 'keyframe_$saveName',
                jsonValue: keyframeJson,
              );

              // 创建 SnackBar
              final snackBar = SnackBar(
                content: const Text("保存成功"), // 提示文本
                duration: const Duration(seconds: 2), // 显示时长（默认 4 秒）
                backgroundColor: Colors.green, // 背景色
              );

              // 显示 SnackBar（需通过 ScaffoldMessenger）
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(snackBar);

              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text('确定'),
          ),
        ],
      );
    },
  );
}

/// 根据关节的位置信息生成关键帧
/// 便利关节位置信息，
Keyframe generateKeyframe(JointsState positions, String inputName) {
  final positionMap = positions.toJson();

  final keyframe = Keyframe(
    name: inputName,
    createTime: DateFormat('yyyy-MM-dd HH-mm-ss').format(DateTime.now()),
    children: [],
  );
  positionMap.forEach((key, value) {
    final motorId = jointIdMap[key];
    if (motorId == null) return;
    final item = KeyframeItem(location: value, motorId: motorId);
    keyframe.children.add(item);
  });

  return keyframe;
}
