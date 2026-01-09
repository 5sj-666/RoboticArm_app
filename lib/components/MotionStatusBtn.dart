import "package:flutter/material.dart";
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robotic_arm_app/cubit/motions_cubit.dart';

class MotionStatusBtn extends StatelessWidget {
  const MotionStatusBtn({super.key});

  @override
  Widget build(BuildContext context) {
    MotionsCubit motionsCubit = BlocProvider.of<MotionsCubit>(context);
    return BlocBuilder<MotionsCubit, MotionsState>(
      builder: (context, state) {
        return Wrap(
          children: [
            if (state.status == MotionStatus.idle)
              OutlinedButton(
                onPressed: () {
                  print('空闲,点击过渡到prepare');
                  if (state.currentMotion == null) {
                    final snackBar = SnackBar(
                      content: const Text("请选择一个动作"),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  } else {
                    motionsCubit.updateStatus(MotionStatus.prepare);
                  }
                },
                child: Text('空闲'),
              )
            else if (state.status == MotionStatus.prepare)
              FilledButton(
                onPressed: () {
                  print('准备,点击过渡到ready');
                  motionsCubit.updateStatus(MotionStatus.preparing);
                },
                child: Text('准备'),
              )
            else if (state.status == MotionStatus.preparing)
              OutlinedButton(
                onPressed: () {
                  print('准备中');
                  // motionsCubit.updateStatus(MotionStatus.preparing);
                },
                child: Text('准备中'),
              )
            else if (state.status == MotionStatus.ready)
              FilledButton(
                onPressed: () {
                  print('就绪,点击过渡到running');
                  motionsCubit.updateStatus(MotionStatus.running);
                },
                child: Text('就绪'),
              )
            else if (state.status == MotionStatus.running)
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.pause, color: Colors.blue),
                tooltip: '运行中',
                onPressed: () {
                  print('stop motion');
                  // motionsCubit.updateState(false);
                  motionsCubit.updateStatus(MotionStatus.paused);
                },
              )
            else if (state.status == MotionStatus.paused)
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.blue),
                tooltip: '开始',
                onPressed: () {
                  print('play motions');
                  motionsCubit.updateStatus(MotionStatus.running);
                },
              )
            else if (state.status == MotionStatus.finished)
              OutlinedButton(
                onPressed: () {
                  print('播放结束,点击过渡到idle');
                  motionsCubit.updateStatus(MotionStatus.prepare);
                },
                child: Text('结束'),
              ),
          ],
        );
      },
    );
  }
}
