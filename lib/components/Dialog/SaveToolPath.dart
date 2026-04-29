import "package:flutter/material.dart";
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robotic_arm_app/cubit/motions_cubit.dart';
import 'package:flutter/services.dart';
import 'package:robotic_arm_app/cubit/toolPath_cubit.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:robotic_arm_app/components/Bezier/Dialog.dart';
import 'package:robotic_arm_app/components/Bezier/Svg.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'package:robotic_arm_app/utils/sharedPreferences.dart';

import 'dart:convert';

Future<void> saveToolPath({
  required BuildContext context,
  required MotionsCubit motionsCubit,
}) async {
  ToolPathCubit toolPathCubit = BlocProvider.of<ToolPathCubit>(context);
  final nodes = toolPathCubit.state.tempNodes;
  final timingFunc = toolPathCubit.state.timingFunc;

  String getPositionString(three.Vector3 v) {
    print("x11: ${double.parse(v.x.toStringAsFixed(4))}");
    return "{x: ${double.parse(v.x.toStringAsFixed(4))}, y: ${double.parse(v.y.toStringAsFixed(4))}, z: ${double.parse(v.z.toStringAsFixed(4))}}";
  }

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      final _motionNameCtrl = TextEditingController(
        text: toolPathCubit.state.tempName,
      );
      final timeController = TextEditingController(
        text: toolPathCubit.state.time.toString(),
      );
      return AlertDialog(
        title: Text('保存末端路径', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width / 5 * 4,
          height: 250,
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
                      onChanged: (value) {
                        toolPathCubit.setTempName(value);
                      },
                    ),
                  ),
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
                        builder: (context) =>
                            SetBezier(initTimingFunc: timingFunc),
                      );
                      if (customTimingFunc != null) {
                        toolPathCubit.setTimingFunc(customTimingFunc);
                        // print(
                        //   '---更改末端路径timingFunc: ${toolPathCubit.state.timingFunc}',
                        // );
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
              SizedBox(height: 10),
              Row(
                children: [
                  Text("运行时间"),
                  SizedBox(
                    width: 120,
                    height: 60,
                    child: TextField(
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ), // 弹出数字键盘
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d*$'),
                        ),
                      ],
                      controller: timeController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '运行时间/s',
                      ),
                      onChanged: (value) {
                        toolPathCubit.setTime(double.tryParse(value) ?? 1.0);
                      },
                      onTap: () {
                        // 延迟设置全选
                        Future.delayed(Duration(milliseconds: 10), () {
                          // 全选输入框内容
                          timeController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: timeController.text.length,
                          );
                        });
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
                time: toolPathCubit.state.time,
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
            },
            child: Text('确定'),
          ),
        ],
      );
    },
  );
}
