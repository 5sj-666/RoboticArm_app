import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:robotic_arm_app/utils/motorCmd.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'dart:convert';
import 'package:robotic_arm_app/cubit/joints_cubit.dart';
import 'package:robotic_arm_app/cubit/motions_cubit.dart';
import 'package:robotic_arm_app/cubit/ble_cubit.dart';
import 'package:robotic_arm_app/cubit/toolPath_cubit.dart';
import 'package:robotic_arm_app/pages/devices/motor/motorLogCubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:robotic_arm_app/utils/sharedPreferences.dart';
import 'package:robotic_arm_app/types/motions.dart';
// import 'package:intl/intl.dart';
import 'package:robotic_arm_app/components/MotionStatusBtn.dart';
import 'package:robotic_arm_app/pages/devices/sliding_collapse.dart';
import 'package:robotic_arm_app/pages/devices/sliding_panel.dart';
import 'package:robotic_arm_app/cubit/keyframe_cubit.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:robotic_arm_app/components/Bezier/Dialog.dart';
import 'package:robotic_arm_app/components/Bezier/Svg.dart';

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
  late ToolPathCubit toolPathCubit;

  @override
  void initState() {
    super.initState();
    motionsCubit = BlocProvider.of<MotionsCubit>(context);
    bleCubit = BlocProvider.of<BleCubit>(context);
    bleCubit.init();
    motorLogCubit = BlocProvider.of<MotorLogCubit>(context);
    toolPathCubit = BlocProvider.of<ToolPathCubit>(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    jointsCubit = BlocProvider.of<JointsCubit>(context);
    PanelController _pc = PanelController();
    final motorCmd = MotorCmdGenerator();

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
            child: Scrollbar(
              controller: sc,
              child: ListView(
                // mainAxisAlignment: MainAxisAlignment.start,
                controller: sc,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                              borderRadius: BorderRadius.all(
                                Radius.circular(12.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 14.0),
                        child: slidingCollapse(bleCubit),
                      ),
                    ],
                  ),
                  SlidingPanelContent(
                    jointsCubit: jointsCubit,
                    motionsCubit: motionsCubit,
                    bleCubit: bleCubit,
                    motorLogCubit: motorLogCubit,
                  ),

                  if (motionsCubit.state.status == MotionStatus.idle ||
                      motionsCubit.state.status == MotionStatus.goToZero)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        FilledButton(
                          onPressed: () {
                            KeyframeCubit kfCubit =
                                BlocProvider.of<KeyframeCubit>(context);
                            kfCubit.switchOptType(OptType.add, null);
                            context.router.push(
                              NamedRoute('DesignMotionRoute'),
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
                        FilledButton(
                          onPressed: () {
                            print('保存末端运行路径');
                            saveToolPath(
                              context: context,
                              // nodes: toolPathCubit.state.tempNodes,
                              toolPathCubit: toolPathCubit,
                              motionsCubit: motionsCubit,
                            );
                            // saveDialog(
                            //   context: context,
                            //   jointsCubit: jointsCubit,
                            // );
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll<Color>(
                              Colors.blue.shade300,
                            ),
                          ),
                          child: const Text(
                            '保存路径',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  if (motionsCubit.state.status == MotionStatus.idle ||
                      motionsCubit.state.status == MotionStatus.goToZero)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // 六个关节都使能
                            for (int i = 0; i < 6; i++) {
                              final motorId = 21 + i;
                              final enableCmd = motorCmd.generateCMD('enable', {
                                'motorId': motorId,
                              });

                              bleCubit.sendSingleCmd(enableCmd);
                            }
                          },
                          child: Text('使能'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // 六个关节都使能
                            for (int i = 0; i < 6; i++) {
                              final motorId = 21 + i;
                              final disableCmd = motorCmd.generateCMD(
                                'disable',
                                {'motorId': motorId},
                              );

                              bleCubit.sendSingleCmd(disableCmd);
                            }
                          },
                          child: Text('停止'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // 设置当前为零点，并移动到零点
                            for (int i = 0; i < 6; i++) {
                              final motorId = 21 + i;
                              final setAsZero = motorCmd.generateCMD(
                                'setAsZero',
                                {'motorId': motorId},
                              );
                              bleCubit.sendSingleCmd(setAsZero);
                              final runmodeCmd = motorCmd.generateCMD(
                                'run_mode',
                                {'motorId': motorId, 'run_mode': 1},
                              );
                              bleCubit.sendSingleCmd(runmodeCmd);
                              // 设置速度
                              final speedCmd = motorCmd.generateCMD(
                                'limit_spd',
                                {'motorId': motorId, 'limit_spd': 2.0},
                              );
                              bleCubit.sendSingleCmd(speedCmd);
                              // 移动到零点
                              final locRefCmd = motorCmd.generateCMD(
                                'loc_ref',
                                {'motorId': motorId, 'loc_ref': 0.0},
                              );
                              bleCubit.sendSingleCmd(locRefCmd);
                            }
                          },
                          child: Text('初始化'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            motionsCubit.updateStatus(MotionStatus.goToZero);
                            print('归零');
                          },
                          child: Text('归零'),
                        ),
                      ],
                    ),

                  // ElevatedButton(
                  //   onPressed: () {
                  //     print('设计路径');
                  //     context.router.push(NamedRoute('DesignToolPathRoute'));
                  //   },
                  //   child: Text('设计路径'),
                  // ),
                  // if (motionsCubit.state.status != MotionStatus.idle &&
                  //     motionsCubit.state.status != MotionStatus.goToZero)
                  if (motionsCubit.state.currentMotion != null)
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
              // ignore: use_build_context_synchronously
              KeyframeCubit kfCubit = BlocProvider.of<KeyframeCubit>(context);
              kfCubit.init();

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

Future<void> saveToolPath({
  required BuildContext context,
  // required JointsCubit jointsCubit,
  // required List<three.Vector3> nodes,
  required ToolPathCubit toolPathCubit,
  required MotionsCubit motionsCubit,
}) async {
  // final _keyframeNameCtrl = TextEditingController();
  final nodes = toolPathCubit.state.tempNodes;
  final timingFunc = toolPathCubit.state.timingFunc;

  print("拖动节点： $nodes");

  /// 对节点的值
  String getPositionString(three.Vector3 v) {
    print("x11: ${double.parse(v.x.toStringAsFixed(4))}");
    return "{x: ${double.parse(v.x.toStringAsFixed(4))}, y: ${double.parse(v.y.toStringAsFixed(4))}, z: ${double.parse(v.z.toStringAsFixed(4))}}";
  }

  // final _tempNodes = nodes.map((item) => setPrecision4(item)).toList();

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      final _motionNameCtrl = TextEditingController();
      return AlertDialog(
        title: Text('保存末端路径', style: TextStyle(fontSize: 16)),
        // content: TextField(controller: _keyframeNameCtrl, autofocus: true),
        content: SizedBox(
          width: MediaQuery.of(context).size.width / 5 * 4,
          height: 180,
          child: Column(
            children: [
              Row(
                children: [
                  Text("名称: "),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 5 * 2,
                    child: TextField(
                      controller: _motionNameCtrl,
                      autofocus: true,
                    ),
                  ),
                  // TextField(controller: _motionNameCtrl, autofocus: true),
                ],
              ),
              SizedBox(
                height: 80,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (int i = 0; i < nodes.length; i++)
                      Text("$i : ${getPositionString(nodes[i])}"),
                  ],
                ),
              ),
              Row(
                children: [
                  Text("贝塞尔曲线: "),
                  InkWell(
                    onTap: () async {
                      final dynamic customTimingFunc = await showDialog(
                        context: context,
                        builder: (context) => SetBezier(
                          // initTimingFunc: item.timingFunction ?? 'linear',
                          // initTimingFunc: 'linear',
                          initTimingFunc: timingFunc,
                        ),
                      );
                      if (customTimingFunc != null) {
                        // item.timingFunction = customTimingFunc;
                        toolPathCubit.setTimingFunc(customTimingFunc);
                        print(
                          '---更改末端路径timingFunc: ${toolPathCubit.state.timingFunc}',
                        );
                        // try {
                        //   // updateKf(item, "changeTimingFunc");
                        // } catch (error) {
                        //   print(error);
                        // }
                      }
                    },
                    child: BlocBuilder<ToolPathCubit, ToolPathState>(
                      builder: (context, toolPathState) {
                        return SvgCubicBezier(
                          timingFunc: toolPathState.timingFunc,
                          bg: Colors.white70,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              /// 构造动作数据，并保存在本地
              final saveName = _motionNameCtrl.text;
              // print("saveName: --$saveName");
              
              List<List<double>> tempPoses = toolPathCubit.state.tempPoses;

              final tempMotion = Motion(
                id: '${DateTime.now()}',
                name: saveName,
                createTime: DateTime.now().millisecondsSinceEpoch.toString(),
                description: '',
                keyframes: [],
                nodes: tempPoses,
                timingFunc: toolPathCubit.state.timingFunc,
              );

              late SnackBar snackBar;
              // 存储在sharedPreferences
              try {
                await SharedPrefsStorage.save(
                  key: 'motion_$saveName',
                  jsonValue: json.encode(tempMotion.toJson()),
                );

                // 创建 SnackBar
                snackBar = SnackBar(
                  content: const Text("保存动作成功"), // 提示文本
                  duration: const Duration(seconds: 2), // 显示时长（默认 4 秒）
                  backgroundColor: Colors.green, // 背景色
                );
              } catch (err) {
                print('动作（路径）保存错误$err');
              }

              if (context.mounted) {
                motionsCubit.init();
                // motionsCubit.init();
                // 显示 SnackBar（需通过 ScaffoldMessenger）
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                Navigator.of(context).pop();
              }

              // if (context.mounted) {
              //   Navigator.of(context).pop();
              // }
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
    // createTime: DateFormat('yyyy-MM-dd HH-mm-ss').format(DateTime.now()),
    createTime: DateTime.now().millisecondsSinceEpoch.toString(),
    positions: List.filled(6, 0.0),
  );
  positionMap.forEach((key, value) {
    final motorId = jointIdMap[key];
    if (motorId == null) return;
    keyframe.positions[motorId - 21] = value;
    // final item = KeyframeItem(location: value, motorId: motorId);
    // keyframe.children.add(item);
  });

  return keyframe;
}
