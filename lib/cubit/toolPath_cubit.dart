/// 运行学逆解相关
import 'package:bloc/bloc.dart';
import 'package:three_js/three_js.dart' as three;
// import 'package:vector_math/vector_math.dart';
// import 'package:three_js_transform_controls/transform_controls_gizmo.dart';

class ToolPathState {
  final String tempName;
  final List<three.Vector3> tempNodes;
  final List<List<double>> tempPoses;
  final String timingFunc;
  final double time;

  // 修正构造函数赋值
  ToolPathState({
    this.tempName = '',
    required this.tempNodes,
    this.timingFunc = "0.3, 0.3, 0.6, 0.6",
    this.tempPoses = const [],
    this.time = 0,
  });

  // 提供一个初始状态的工厂方法
  factory ToolPathState.initial() => ToolPathState(
    tempName: '',
    tempNodes: [],
    timingFunc: "0.3, 0.3, 0.6, 0.6",
    tempPoses: [],
    time: 1.0,
  );

  ToolPathState copyWith({
    List<three.Vector3>? tempNodes,
    List<List<double>>? tempPoses,
    String? timingFunc,
    double? time,
    String? tempName,
  }) {
    return ToolPathState(
      tempNodes: tempNodes ?? this.tempNodes,
      tempPoses: tempPoses ?? this.tempPoses,
      timingFunc: timingFunc ?? this.timingFunc,
      time: time ?? this.time,
      tempName: tempName ?? this.tempName,
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

  void setTime(double time) {
    emit(state.copyWith(time: time));
  }

  void setTempName(String name) {
    emit(state.copyWith(tempName: name));
  }

  void setState({
    List<three.Vector3>? tempNodes,
    List<List<double>>? tempPoses,
    String? timingFunc,
    double? time,
    String? tempName,
  }) {
    emit(
      state.copyWith(
        tempNodes: tempNodes,
        tempPoses: tempPoses,
        timingFunc: timingFunc,
        time: time,
        tempName: tempName,
      ),
    );
  }
}
