import "package:flutter/material.dart";
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robotic_arm_app/cubit/ble_cubit.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:robotic_arm_app/pages/devices/bleDevices.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:toastification/toastification.dart';

class BleStatusBtn extends StatelessWidget {
  const BleStatusBtn({super.key});

  @override
  Widget build(BuildContext context) {
    BleCubit bleCubit = BlocProvider.of<BleCubit>(context);

    return BlocBuilder<BleCubit, BleState>(
      builder: (bleContext, state) {
        return Row(
          children: [
            if (bleCubit.state.status == BleStatus.unknow)
              ElevatedButton(onPressed: () {}, child: Text('未知状态')),

            if (state.status == BleStatus.off)
              ElevatedButton(
                onPressed: () async {
                  final result = await bleCubit.turnOn();

                  toastification.show(
                    type: result
                        ? ToastificationType.success
                        : ToastificationType.error,
                    title: Text(result ? '打开蓝牙成功' : '打开失败，请去系统中打开蓝牙'),
                    autoCloseDuration: const Duration(seconds: 10),
                  );
                },
                child: Text('蓝牙未打开'),
              ),
            if (state.status == BleStatus.on ||
                state.status == BleStatus.disconnected)
              ElevatedButton(
                onPressed: () async {
                  /// 打开全局弹框，其中有蓝牙设备列表
                  String res = await bleCubit.bleScan();
                  if (res != '') {
                    toastification.show(
                      type: ToastificationType.error,
                      title: Text(res),
                      autoCloseDuration: const Duration(seconds: 999),
                    );
                    return;
                  }
                  openDialog(bleCubit);
                },
                child: Text('连接设备'),
              ),
            if (state.status == BleStatus.connecting)
              ElevatedButton(
                onPressed: () {
                  openDialog(bleCubit);
                },
                child: Text('连接中'),
              ),

            if (state.status == BleStatus.connected)
              ElevatedButton(
                onPressed: () {
                  /// 打开全局弹框，其中有蓝牙设备列表
                  openDialog(bleCubit);
                },
                child: Text('已连接'),
              ),
            if (state.status == BleStatus.disconnecting)
              ElevatedButton(
                onPressed: () {
                  openDialog(bleCubit);
                },
                child: Text('断开中'),
              ),
          ],
        );
      },
    );
  }
}

openDialog(BleCubit bleCubit) {
  SmartDialog.show(
    builder: (_) => BlocBuilder<BleCubit, BleState>(
      builder: (bleContext, state) {
        return AlertDialog(
          title: const Text('连接机械臂'),
          content: SizedBox(
            width: double.maxFinite,
            height: 200,
            child: BleDevices(),
          ),
          actions: [
            if (bleCubit.state.scanStatus == ScanStatus.scanning)
              TextButton(
                child: Text('扫描中'),
                onPressed: () async {
                  String res = await bleCubit.bleStopScan();
                  if (res != '') {
                    toastification.show(
                      type: ToastificationType.error,
                      title: Text(res),
                      autoCloseDuration: const Duration(seconds: 999),
                    );
                  }
                },
              ),

            if (bleCubit.state.scanStatus != ScanStatus.scanning)
              TextButton(
                child: Text('扫描设备'),
                onPressed: () {
                  bleCubit.bleScan();
                },
              ),

            TextButton(
              child: const Text('关闭'),
              onPressed: () => SmartDialog.dismiss(),
            ),
          ],
        );
      },
    ),
  );
}
