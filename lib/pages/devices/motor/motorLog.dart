import 'package:flutter/material.dart';
import 'package:robotic_arm_app/pages/devices/motor/motorLogCubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MotorLogPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // final MotorLogCubit motorLogCubit = BlocProvider.of<MotorLogCubit>(context);
    return BlocBuilder<MotorLogCubit, MotorLogState>(
      builder: (context, state) {
        return ListView.builder(
          itemCount: state.list.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(Icons.label),
              title: Text(state.list[index].parseMsg),
              onTap: () {
                // // 点击事件
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(content: Text('点击了 ${items[index]}')),
                // );
              },
            );
          },
        );
      },
    );
  }
}
