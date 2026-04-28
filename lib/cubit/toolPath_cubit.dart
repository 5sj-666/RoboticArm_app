/// 运行学逆解相关
import 'package:bloc/bloc.dart';
import 'package:three_js/three_js.dart' as three;
// import 'package:vector_math/vector_math.dart';
// import 'package:three_js_transform_controls/transform_controls_gizmo.dart';

class ToolPathState {
  final List<three.Vector3> tempNodes;
  final List<List<double>> tempPoses;
  final String timingFunc;

  // 修正构造函数赋值
  ToolPathState({
    required this.tempNodes,
    this.timingFunc = "0.3, 0.3, 0.6, 0.6",
    this.tempPoses = const [],
  });

  // 提供一个初始状态的工厂方法
  factory ToolPathState.initial() => ToolPathState(
    tempNodes: [],
    timingFunc: "0.3, 0.3, 0.6, 0.6",
    tempPoses: [],
  );

  ToolPathState copyWith({
    List<three.Vector3>? tempNodes,
    List<List<double>>? tempPoses,
    String? timingFunc,
  }) {
    return ToolPathState(
      tempNodes: tempNodes ?? this.tempNodes,
      tempPoses: tempPoses ?? this.tempPoses,
      timingFunc: timingFunc ?? this.timingFunc,
    );
  }
}

class ToolPathCubit extends Cubit<ToolPathState> {
  ToolPathCubit() : super(ToolPathState.initial());

  void setSingleNode(int index, three.Vector3 value) {
    state.tempNodes[index] = value;
    emit(state.copyWith(tempNodes: state.tempNodes));
  }

  void setNodes(List<three.Vector3> nodes) {
    // state.tempNodes[index] = value;
    emit(state.copyWith(tempNodes: List.from(nodes)));
  }

  void setTimingFunc(String timingFunc) {
    emit(state.copyWith(timingFunc: timingFunc));
  }

  void setTempPose(List<List<double>> pose) {
    emit(state.copyWith(tempPoses: pose));
  }

  void setState(
    List<three.Vector3>? tempNodes,
    List<List<double>>? tempPoses,
    String? timingFunc,
  ) {
    emit(
      state.copyWith(
        tempNodes: tempNodes,
        tempPoses: tempPoses,
        timingFunc: timingFunc,
      ),
    );
  }
}
