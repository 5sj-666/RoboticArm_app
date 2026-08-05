import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robotic_arm_app/cubit/ble_cubit.dart';
// import 'package:auto_route/auto_route.dart';
import 'package:toastification/toastification.dart';

class BleDevices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // return BlocProvider<BleCubit, BleState>(
    final BleCubit bleCubit = BlocProvider.of<BleCubit>(context);
    return BlocBuilder<BleCubit, BleState>(
      builder: (context, state) {
        return ListView(
          children: state.devices.map((device) {
            return ListTile(
              title: Text(
                device.advName.isNotEmpty
                    ? device.advName
                    : device.platformName.isNotEmpty
                    ? device.platformName
                    : device.remoteId.str,
              ),
              // subtitle: Text(device.advName),
              trailing:
                  state.device?.remoteId.str == device.remoteId.str &&
                      (state.status == BleStatus.connecting ||
                          state.status == BleStatus.connected ||
                          state.status == BleStatus.disconnecting)
                  ? FilledButton(
                      style: ButtonStyle(
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                        // backgroundColor
                      ),
                      child: Text(
                        state.status == BleStatus.connecting
                            ? '连接中'
                            : state.status == BleStatus.disconnecting
                            ? '断开中'
                            : '断开连接',
                      ),
                      onPressed: () async {
                        if (state.status == BleStatus.disconnecting) {
                          return;
                        }
                        if (device.isConnected == false) return;
                        String result = await bleCubit.bleDisconnectDevice(
                          device,
                        );
                        toastification.show(
                          type: result == ''
                              ? ToastificationType.success
                              : ToastificationType.error,
                          title: Text(result == '' ? '已断开设备' : result),
                          autoCloseDuration: const Duration(seconds: 999),
                        );
                      },
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        bool result = await bleCubit.bleConnectDevice(device);
                        if (result) {
                          toastification.show(
                            type: ToastificationType.success,
                            title: Text(
                              '已连接到设备 ${device.advName.isNotEmpty
                                  ? device.advName
                                  : device.platformName.isNotEmpty
                                  ? device.platformName
                                  : device.remoteId.str}',
                            ),
                            autoCloseDuration: const Duration(seconds: 999),
                          );
                        } else {
                          toastification.show(
                            type: ToastificationType.error,
                            title: Text('连接设备失败'),
                            autoCloseDuration: const Duration(seconds: 999),
                          );
                        }
                      },
                      child: Text('连接'),
                    ),
            );
          }).toList(),
        );
      },
    );
  }
}
