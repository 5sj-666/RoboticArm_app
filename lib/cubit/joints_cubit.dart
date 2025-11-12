import 'package:bloc/bloc.dart';
import 'dart:convert';
import 'package:robotic_arm_app/types/motions.dart';

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
class JointsCubit extends Cubit<Joints> {
  JointsCubit() : super(const Joints()) {
    // print('----JointsCubit init');
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

  void setJoints(Joints newJoints) {
    emit(newJoints);
  }

  String getJointsWithJSON() {
    // final jointsMap = jsonDecode(json.encode(state.toJson())) as Map<String, dynamic>;
    // final joints = Joints.fromJson(jointsMap);
    return json.encode(state.toJson());
  }
}
