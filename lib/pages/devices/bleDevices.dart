import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robotic_arm_app/cubit/ble_cubit.dart';
// import 'package:auto_route/auto_route.dart';

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
                          state.status == BleStatus.connected)
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
                        state.status == BleStatus.connecting ? '连接中' : '断开连接',
                      ),
                      onPressed: () async {
                        if (device.isConnected == false) return;
                        bool result = await bleCubit.bleDisconnectDevice(
                          device,
                        );
                        SnackBar snackBar;
                        if (result) {
                          snackBar = SnackBar(content: Text('已断开设备'));
                        } else {
                          snackBar = SnackBar(content: Text('断开设备失败'));
                        }
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      },
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        bool result = await bleCubit.bleConnectDevice(device);
                        SnackBar snackBar;
                        if (result) {
                          snackBar = SnackBar(
                            content: Text(
                              '已连接到设备 ${device.advName.isNotEmpty
                                  ? device.advName
                                  : device.platformName.isNotEmpty
                                  ? device.platformName
                                  : device.remoteId.str}',
                            ),
                          );
                        } else {
                          snackBar = SnackBar(content: Text('连接设备失败'));
                        }

                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
