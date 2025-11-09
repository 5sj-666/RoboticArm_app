import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'dart:convert';
import 'package:robotic_arm_app/cubit/joints_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:robotic_arm_app/components/joint_slider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:robotic_arm_app/utils/sharedPreferences.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class DeviceInformationPage extends StatefulWidget {
  const DeviceInformationPage({super.key});

  @override
  State<DeviceInformationPage> createState() => _deviceInformationPage();
}

// ignore: camel_case_types
class _deviceInformationPage extends State<DeviceInformationPage> {
  late JointsCubit jointsCubit;

  String motionsName = "motions名称很长,需要滚动起来起来";
  late ScrollController _scrollController;
  late Timer _timer;
  late TextPainter motionsNamePainter;

  // const List<String> jointNameMap = [joint];

  final List<double> _jointValues = List.filled(6, 0.0);
  void _updateJointValue(double newVal, int index) {
    print('_updateJointValue: newval: $newVal ,index$index');
    setState(() {
      _jointValues[index] = newVal;
    });
    Future.delayed(const Duration(seconds: 0), () {
      jointsCubit.setSingleJoint('joint${index + 1}', newVal);
      print('Information Page 关节$index: ${jointsCubit.state}');
    });
  }

  @override
  void initState() {
    super.initState();
    // ignore: no_leading_underscores_for_local_identifiers
    _scrollController = ScrollController();

    // 计算文字宽度
    motionsNamePainter = TextPainter(
      text: TextSpan(
        text: motionsName,
        style: TextStyle(color: Colors.grey),
      ),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout();

    void scrollFunc() {
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

    print("text 长度${motionsNamePainter.width}");
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

    // TextInputControl control = TextInputControl();
    // ignore: no_leading_underscores_for_local_identifiers

    // print('Information Page 关节1: ${jointsCubit.state.joint1}');

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
      // 面板内容
      panel: Padding(
        padding: EdgeInsets.only(top: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Wrap(
              children: [
                for (int i = 0; i < _jointValues.length; i++)
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: JointSlider(
                      title: '关节${i + 1}:',
                      value: _jointValues[i],
                      onValueChanged: _updateJointValue,
                      index: i,
                      min: i == 1 ? -130.0 : -180.0,
                      max: i == 1 ? 130.0 : 180.0,
                    ),
                  ),
              ],
            ),
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
                    saveDialog(context: context, jointsCubit: jointsCubit);
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
          ],
        ),
      ),
      // 面板顶部的滑块
      collapsed: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                iconSize: 32,
                tooltip: '蓝牙',
                icon: const Icon(Icons.bluetooth, color: Colors.grey),
                onPressed: () {
                  print('蓝牙');
                },
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("动作", style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
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
                ],
              ),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.blue),
                tooltip: '开始',
                onPressed: () {
                  print('play motions');
                },
              ),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.stop_rounded, color: Colors.blue),
                tooltip: '停止',
                onPressed: () {
                  print('stop motions');
                },
              ),
            ],
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
              Keyframe keyframe = generateKeyfreme(jointsCubit.state, saveName);
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
Keyframe generateKeyfreme(Joints positions, String inputName) {
  final positionMap = positions.toJson();

  final keyframe = Keyframe(
    name: inputName,
    createTime: DateFormat('yyyy-MM-dd HH-mm-ss').format(DateTime.now()),
    children: [],
  );
  positionMap.forEach((key, value) {
    final item = KeyframeItem(location: value, motorId: jointIdMap[key]);
    keyframe.children.add(item);
  });

  return keyframe;
}
