/// 运行学逆解相关
import 'package:bloc/bloc.dart';
// import 'package:three_js/three_js.dart';
import 'package:three_js_transform_controls/transform_controls_gizmo.dart';

class Pose {
  final GizmoType mode; // 操作类型：移动和旋转； translate ｜ rotate | scale;在此只会用到移动和旋转
  // final Vector3 position; // 位置 (x, y, z)
  // final Quaternion quaternion; // 姿态四元数 (x, y, z, w)
  // final Vector3 eulerXYZ; // 欧拉角 (单位：弧度)
  // final Matrix4 transformation; // 完整 4x4 变换矩阵

  Pose({
    this.mode = GizmoType.translate,
    // required this.position,
    // required this.quaternion,
    // required this.eulerXYZ,
    // required this.transformation,
  });

  // @override
  // String toString() {
  //   return 'Position: ${position.x.toStringAsFixed(3)}, ${position.y.toStringAsFixed(3)}, ${position.z.toStringAsFixed(3)}\n'
  //       'EulerXYZ: ${eulerXYZ.x.toStringAsFixed(3)}, ${eulerXYZ.y.toStringAsFixed(3)}, ${eulerXYZ.z.toStringAsFixed(3)}';
  // }
}

class IKState {
  // final int index;
  // final
  // HomeState({this.index = 0});

  final Pose dragPose;
  IKState({Pose? dragPose}) : dragPose = dragPose ?? Pose();

  copyWith({Pose? dragPose}) {
    return IKState(dragPose: dragPose ?? this.dragPose);
  }
}

class IKCubit extends Cubit<IKState> {
  IKCubit() : super(IKState());

  void setMode(GizmoType mode) {
    final newPose = Pose(mode: mode);
    emit(state.copyWith(dragPose: newPose));
  }
}
