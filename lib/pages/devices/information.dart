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
import 'dart:ui' as ui;
import 'package:robotic_arm_app/pages/devices/bleDevices.dart';
import 'package:robotic_arm_app/pages/devices/motor/motorLog.dart';
import 'package:robotic_arm_app/components/MotionStatusBtn.dart';

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

  // String motionsName = "motions名称很长,需要滚动起来起来";
  String motionsName = "";
  late ScrollController _scrollController;
  late Timer _timer;
  late TextPainter motionsNamePainter;

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
    _scrollController = ScrollController();

    // initialize motionsCubit before reading its state
    motionsCubit = BlocProvider.of<MotionsCubit>(context);
    bleCubit = BlocProvider.of<BleCubit>(context);
    bleCubit.init();
    motorLogCubit = BlocProvider.of<MotorLogCubit>(context);
  }

  // 判断动作名称是否需要滚动
  void needScrollText(str) {
    // 计算文字宽度
    motionsNamePainter = TextPainter(
      text: TextSpan(
        text: str,
        style: TextStyle(color: Colors.grey),
      ),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout();

    void scrollFunc() {
      try {
        _timer.cancel();
      } catch (err) {
        ///
      }

      bool directionLTR = true; // 标记方向
      // print();
      // if (_scrollController.offset > 120) {
      _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
        // 每隔500毫秒滚动一次
        if (_scrollController.hasClients) {
          if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent) {
            directionLTR = false; // 改变方向
          } else if (_scrollController.offset <=
              _scrollController.position.minScrollExtent) {
            directionLTR = true; // 改变方向
          }

          _scrollController.animateTo(
            _scrollController.offset + (directionLTR ? 20 : -20),
            duration: Duration(milliseconds: 500),
            curve: Curves.linear,
          );
        }
      });
      // }
    }

    // print("text 长度${motionsNamePainter.width}");
    if (motionsNamePainter.width >= 120) {
      scrollFunc();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    jointsCubit = BlocProvider.of<JointsCubit>(context);

    Motion? curMotion = motionsCubit.state.currentMotion;
    if (curMotion != null) {
      motionsName = curMotion.name;
    }

    needScrollText(motionsName);
    PanelController _pc = PanelController();

    bool isPanelOpen() {
      bool isOpened = _pc.isAttached && _pc.isPanelOpen;
      print('isOpened: $isOpened');
      return isOpened;
    }

    return SlidingUpPanel(
      // color: Colors.black,
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      // 面板关闭时显示的高度
      minHeight: 60,
      // 面板打开时显示的高度
      maxHeight: 300,
      backdropEnabled: false,
      panelSnapping: true, //自动吸附效果
      onPanelSlide: (position) {},
      controller: _pc,

      // 面板内容
      // panel:
      panelBuilder: (sc) => IgnorePointer(
        ignoring: isPanelOpen(),
        child: BlocBuilder<MotionsCubit, MotionsState>(
          builder: (context, motionState) {
            return Padding(
              padding: EdgeInsets.only(top: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  BlocBuilder<JointsCubit, JointsState>(
                    builder: (context, state) {
                      return Wrap(
                        children: [
                          // for (int i = 0; i < 6; i++)
                          //   FractionallySizedBox(
                          //     widthFactor: 0.5,
                          //     child: JointSlider(
                          //       title: '关节${i + 1}:',
                          //       // value: _jointValues[i],
                          //       value: jointsCubit.getSingleJoint(i),
                          //       onValueChanged: _updateJointValue,
                          //       index: i,
                          //       min: i == 1 ? -130.0 : -145.0,
                          //       max: i == 1 ? 130.0 : 145.0,
                          //       onChangeEnd: _updateJointEnd,
                          //     ),
                          //   ),
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
                                  motionsCubit.state.status !=
                                  MotionStatus.idle,
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
                                  motionsCubit.state.status !=
                                  MotionStatus.idle,
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
                                  motionsCubit.state.status !=
                                  MotionStatus.idle,
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
                                  motionsCubit.state.status !=
                                  MotionStatus.idle,
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
                                  motionsCubit.state.status !=
                                  MotionStatus.idle,
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
                                  motionsCubit.state.status !=
                                  MotionStatus.idle,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (motionsCubit.state.status == MotionStatus.idle)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        FilledButton(
                          onPressed: () {
                            context.router.push(
                              NamedRoute('OrderKeyframeRoute'),
                            );
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
                        ElevatedButton(onPressed: () {}, child: Text('使能')),
                        ElevatedButton(onPressed: () {}, child: Text('置零')),
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
                            print(
                              '--卸载动作---${motionsCubit.state.currentMotion}',
                            );
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
      ),

      // 面板顶部的滑块
      collapsed: IgnorePointer(
        ignoring: isPanelOpen(),
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white,
            // color: Colors.blueGrey,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Center(
            child: BlocBuilder<MotionsCubit, MotionsState>(
              builder: (context, state) {
                // motionsName =
                //     state.currentMotion?.name ?? '-------这是个测试名称-------';
                motionsName = state.currentMotion?.name ?? '';
                needScrollText(motionsName);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    BlocBuilder<BleCubit, BleState>(
                      builder: (bleContext, state) {
                        return Row(
                          children: [
                            if (state.status == BleStatus.unknow ||
                                state.status == BleStatus.off ||
                                state.status == BleStatus.on)
                              IconButton(
                                iconSize: 32,
                                tooltip: '蓝牙',
                                icon: bleCubit.state.isBleOn
                                    ? const Icon(
                                        Icons.bluetooth,
                                        color: Colors.blue,
                                      )
                                    : const Icon(
                                        Icons.bluetooth,
                                        color: Colors.grey,
                                      ),
                                onPressed: () async {
                                  print('蓝牙');
                                  final result = await bleCubit.turnOn();
                                  // 请求打开蓝牙的permission
                                  SnackBar snackBar;
                                  if (result) {
                                    snackBar = SnackBar(
                                      content: Text('打开蓝牙成功'),
                                    );
                                  } else {
                                    snackBar = SnackBar(
                                      content: Text('打开失败，请去系统中打开蓝牙'),
                                    );
                                  }

                                  ScaffoldMessenger.of(
                                    // ignore: use_build_context_synchronously
                                    context,
                                  ).showSnackBar(snackBar);
                                },
                              ),
                            if (state.status == BleStatus.scan ||
                                state.status == BleStatus.on ||
                                state.status == BleStatus.scaned)
                              ElevatedButton(
                                onPressed: () {
                                  _showDialog(context);
                                  print('---点击扫描----');
                                  bleCubit.bleScan();
                                },
                                child: Text('扫描设备'),
                              ),
                            if (state.status == BleStatus.scaning)
                              ElevatedButton(
                                onPressed: () {
                                  print('---点击暂停扫描----');
                                  bleCubit.bleStopScan();
                                },
                                child: Text('扫描中'),
                              ),

                            if (state.status == BleStatus.connected ||
                                state.status == BleStatus.connecting)
                              ElevatedButton(
                                onPressed: () {
                                  print('---已连接设备, 点击查看列表----');
                                  _showDialog(context);
                                },
                                child: Text(
                                  state.status == BleStatus.connected
                                      ? '已连接'
                                      : '连接中',
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("动作", style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        // BlocBuilder<MotionsCubit, MotionsState>(
                        //   builder: (context, state) {
                        //     motionsName =
                        //         state.currentMotion?.name ?? '-------这是个测试名称-------';
                        //     needScrollText(motionsName);
                        //     return
                        motionsNamePainter.width < 120
                            ? Text(motionsName, textAlign: TextAlign.center)
                            : SizedBox(
                                width: 120, // 设置一个固定宽度
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  scrollDirection: Axis.horizontal, // 水平滚动
                                  child: Text(
                                    motionsName,
                                    // 禁止自动换行
                                    softWrap: false,
                                  ),
                                ),
                              ),
                        // },
                        // ),
                      ],
                    ),
                    MotionStatusBtn(),
                    TextButton(
                      onPressed: () {
                        print('使能');
                        // bleCubit.sendEnableCmd();
                        // bleCubit.sendEnableCmd();
                      },
                      child: Text('使能'),
                    ),
                    TextButton(
                      onPressed: () {
                        print('日志');
                        _showMotorLog(context);
                      },
                      child: Text('日志'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
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

Future<void> _showDialog(context) async {
  return showDialog<void>(
    animationStyle: AnimationStyle(),
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('连接机械臂'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: BleDevices(),
        ),
        actions: [
          TextButton(
            child: const Text('关闭'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}

Future<void> _showMotorLog(context) async {
  final motorLogCubit = BlocProvider.of<MotorLogCubit>(context);
  return showDialog<void>(
    animationStyle: AnimationStyle(),
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('电机日志'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: MotorLogPage(),
        ),
        actions: [
          TextButton(
            child: const Text('清空'),
            onPressed: () {
              motorLogCubit.clearLog();
            },
          ),
          TextButton(
            child: const Text('关闭'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}
