import 'package:bloc/bloc.dart';
import 'package:logger/logger.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'package:robotic_arm_app/utils/sharedPreferences.dart';
// import 'package:logger/logger.dart';
import 'dart:convert';

final logger = Logger();

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

// 定义动作状态枚举 播放结束： finished
// 需要准备好,才能运行
enum MotionStatus { idle, prepare, preparing, ready, running, paused, finished }

class MotionsState {
  final List<Motion> motions;
  final Motion? currentMotion;
  final bool runing;
  final bool firstRun;
  final MotionStatus status;

  // final int elapsedTime;

  MotionsState({
    required this.motions,
    this.currentMotion,
    this.runing = false,
    this.firstRun = true,
    this.status = MotionStatus.idle,
    // this.elapsedTime = 0,
  });

  MotionsState copyWith({
    List<Motion>? motions,
    Motion? currentMotion,
    bool? runing,
    bool? firstRun,
    MotionStatus? status,
    // int? elapsedTime,
  }) {
    // print('MotionsState');
    return MotionsState(
      motions: motions ?? this.motions,
      currentMotion: currentMotion ?? this.currentMotion,
      runing: runing ?? this.runing,
      firstRun: firstRun ?? this.firstRun,
      status: status ?? this.status,
      // elapsedTime: elapsedTime ?? this.elapsedTime,
    );
  }

  // 待优化
  MotionsState clearCurMotion({
    List<Motion>? motions,
    Motion? currentMotion,
    bool? runing,
    bool? firstRun,
    MotionStatus? status,
  }) {
    return MotionsState(
      motions: motions ?? this.motions,
      currentMotion: null,
      runing: runing ?? this.runing,
      firstRun: firstRun ?? this.firstRun,
      status: MotionStatus.idle,
    );
  }
}

class MotionsCubit extends Cubit<MotionsState> {
  MotionsCubit() : super(MotionsState(motions: [], currentMotion: null)) {
    // print('---motionsCubit init');
    _initMotions();
  }

  void _initMotions() async {
    // print('----initMotions----');
    // 从sharedpreference中获取
    Map<String, dynamic> resultList = await SharedPrefsStorage.findByKeyPrefix(
      'motion',
    );

    List<Motion> list = [];

    resultList.forEach((key, value) {
      try {
        // print('---motionCubit for: $value');
        final jsonMap = json.decode(value);
        list.add(Motion.fromJson(jsonMap));
      } catch (error) {
        logger.w(error);
      }
    });

    // emit(MotionsState(motions: list));
    emit(state.copyWith(motions: list));

    // print('motionscubic初始状态 ');
  }

  void update() {
    print('motionscubic更新状态 ');
    _initMotions();
  }

  Motion findById(String id) {
    var result = state.motions.where((motion) => motion.id == id);
    return result.first;
  }

  bool setCurMotion(Motion motion) {
    // state.currentMotion = motion;
    try {
      emit(state.copyWith(motions: state.motions, currentMotion: motion));
      return true;
    } catch (error) {
      print('motions cubit: error $error');
      return false;
    }
  }

  void clearCurMotion() {
    emit(state.clearCurMotion());
  }

  bool updateState(bool runing) {
    try {
      emit(state.copyWith(runing: runing));
      return true;
    } catch (error) {
      print('motions cubit: error $error');
      return false;
    }
  }

  bool updateStatus(MotionStatus status) {
    try {
      // emit(state.copyWith(runing: runing));
      emit(state.copyWith(status: status));
      return true;
    } catch (error) {
      print('motions cubit: error $error');
      return false;
    }
  }

  // Motion getCurMotion() {
  //   // return findById(state.currentMotion);
  // }

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
