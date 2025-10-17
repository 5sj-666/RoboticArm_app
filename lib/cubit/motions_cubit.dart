import 'package:bloc/bloc.dart';
import 'package:robotic_arm_app/types/motions.dart';

// ignore: slash_for_doc_comments
/**
   {
    id: "", // 时间戳 + 随机数
    name: '测试动作',
    description: '这是一个测试动作',
    joints: [
      {
        name: "joint1",
        motorId: 21,
        keyframes: [
          {
            time: 0,
            location: 20,
            // timingFunction: "linear",
            timingFunction: "0,0,1,1",
            motorId: 21,
          },
          {
            time: 1000,
            location: 100,
            // timingFunction: "linear",
            timingFunction: "0,0,1,1",
            motorId: 21,
          },
        ],
      }, 
  **/

class MotionsState {
  final List<Motion> motions;
  final String currentMotion;

  MotionsState({required this.motions, required this.currentMotion});

  MotionsState copyWith({List<Motion>? motions, String? currentMotion}) {
    return MotionsState(
      motions: motions ?? this.motions,
      currentMotion: currentMotion ?? this.currentMotion,
    );
  }
}

class MotionsCubit extends Cubit<MotionsState> {
  MotionsCubit() : super(MotionsState(motions: [], currentMotion: ''));

  void setMotions(List<Motion> motions) {
    // emit(state.copyWith(motions: motions));
  }

  void setCurrentMotion(String motion) {
    // emit(state.copyWith(currentMotion: motion));
  }

  void addMotion(String motion) {
    // final updatedMotions = List<Motion>.from(state.motions)..add(motion);
    // emit(state.copyWith(motions: updatedMotions));
  }

  void deleteMotion(String motion) {
    // final updatedMotions = List<Motion>.from(state.motions)..remove(motion);
    // emit(state.copyWith(motions: updatedMotions));
  }

  void deleteMotionById(String id) {
    // final updatedMotions =
    // state.motions.where((motion) => motion != id).toList();
    // emit(state.copyWith(motions: updatedMotions));
  }

  void clearMotions() {
    // emit(state.copyWith(motions: []));
  }
}
