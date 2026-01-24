import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robotic_arm_app/cubit/motions_cubit.dart';
import 'package:robotic_arm_app/cubit/ble_cubit.dart';
import 'package:robotic_arm_app/pages/devices/motor/motorLog.dart';
import 'package:robotic_arm_app/components/MotionStatusBtn.dart';
import 'package:robotic_arm_app/pages/devices/bleDevices.dart';
// import 'package:robotic_arm_app/pages/devices/motor/motorLog.dart';
import 'package:robotic_arm_app/pages/devices/motor/motorLogCubit.dart';

Widget slidingCollapse(BleCubit bleCubit) {
  ScrollController _scrollController = ScrollController();
  late Timer _timer;
  late TextPainter motionsNamePainter;

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
      // if (_scrollController.offset > 100) {
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
    if (motionsNamePainter.width >= 100) {
      scrollFunc();
    }
  }

  // return Text('测试名称');
  return Container(
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
          final motionsName = state.currentMotion?.name ?? '';
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
                              ? const Icon(Icons.bluetooth, color: Colors.blue)
                              : const Icon(Icons.bluetooth, color: Colors.grey),
                          onPressed: () async {
                            print('蓝牙');
                            final result = await bleCubit.turnOn();
                            // 请求打开蓝牙的permission
                            SnackBar snackBar;
                            if (result) {
                              snackBar = SnackBar(content: Text('打开蓝牙成功'));
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
                            state.status == BleStatus.connected ? '已连接' : '连接中',
                          ),
                        ),
                    ],
                  );
                },
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("动作", style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 8),

                    motionsNamePainter.width < 100
                        ? Text(
                            motionsName,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          )
                        : SizedBox(
                            width: 100, // 设置一个固定宽度
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
              ),

              MotionStatusBtn(),
              // TextButton(
              //   onPressed: () {
              //     print('使能');
              //     // bleCubit.sendEnableCmd();
              //     // bleCubit.sendEnableCmd();
              //   },
              //   child: Text('使能'),
              // ),
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
  );
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
