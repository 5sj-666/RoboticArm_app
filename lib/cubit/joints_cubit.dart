import 'package:bloc/bloc.dart';
import 'dart:convert';
// import 'package:robotic_arm_app/types/motions.dart';

class JointsState {
  final double joint1;
  final double joint2;
  final double joint3;
  final double joint4;
  final double joint5;
  final double joint6;

  const JointsState({
    this.joint1 = 0.0,
    this.joint2 = 0.0,
    this.joint3 = 0.0,
    this.joint4 = 0.0,
    this.joint5 = 0.0,
    this.joint6 = 0.0,
  });

  JointsState copyWith({
    double? joint1,
    double? joint2,
    double? joint3,
    double? joint4,
    double? joint5,
    double? joint6,
  }) {
    return JointsState(
      joint1: joint1 ?? this.joint1,
      joint2: joint2 ?? this.joint2,
      joint3: joint3 ?? this.joint3,
      joint4: joint4 ?? this.joint4,
      joint5: joint5 ?? this.joint5,
      joint6: joint6 ?? this.joint6,
    );
  }

  JointsState.fromJson(Map<String, dynamic> json)
    : joint1 = json['joint1'] as double,
      joint2 = json['joint2'] as double,
      joint3 = json['joint3'] as double,
      joint4 = json['joint24'] as double,
      joint5 = json['joint5'] as double,
      joint6 = json['joint6'] as double;

  Map<String, dynamic> toJson() => {
    'joint1': joint1,
    'joint2': joint2,
    'joint3': joint3,
    'joint4': joint4,
    'joint5': joint5,
    'joint6': joint6,
  };
}

// ignore: slash_for_doc_comments
/**
  let position = {
    joint1: -(joint1.value * Math.PI) / 180,
    joint2: -(joint2.value * Math.PI) / 180,
    joint3: -(joint3.value * Math.PI) / 180,
    joint4: -(joint4.value * Math.PI) / 180,
    joint5: -(joint5.value * Math.PI) / 180,
  };
 */
class JointsCubit extends Cubit<JointsState> {
  JointsCubit() : super(const JointsState()) {
    // print('----JointsCubit init');
  }

  double getSingleJoint(index) {
    switch (index) {
      case '1':
        return state.joint6;
      case '2':
        return state.joint6;
      case '3':
        return state.joint6;
      case '4':
        return state.joint6;
      case '5':
        return state.joint6;
      case '6':
        return state.joint6;
      default:
        return 0;
    }

    //   break;
    // case 'joint1':
    //   emit(state.copyWith(joint1: val));
    //   break;
    // case 'joint2':
    //   emit(state.copyWith(joint2: val));
    //   break;
    // case 'joint3':
    //   emit(state.copyWith(joint3: val));
    //   break;
    // case 'joint4':
    //   emit(state.copyWith(joint4: val));
    //   break;
    // case 'joint5':
    //   emit(state.copyWith(joint5: val));
    //   break;
    // default:
    //   break;
  }

  void setSingleJoint(jointName, val) {
    switch (jointName) {
      case 'joint6':
        emit(state.copyWith(joint6: val));
        break;
      case 'joint1':
        emit(state.copyWith(joint1: val));
        break;
      case 'joint2':
        emit(state.copyWith(joint2: val));
        break;
      case 'joint3':
        emit(state.copyWith(joint3: val));
        break;
      case 'joint4':
        emit(state.copyWith(joint4: val));
        break;
      case 'joint5':
        emit(state.copyWith(joint5: val));
        break;
      default:
        break;
    }
  }

  void setJoints(JointsState newJoints) {
    emit(newJoints);
  }

  String getJointsWithJSON() {
    // final jointsMap = jsonDecode(json.encode(state.toJson())) as Map<String, dynamic>;
    // final joints = Joints.fromJson(jointsMap);
    return json.encode(state.toJson());
  }
}
