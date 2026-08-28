/// 运行学逆解相关
import 'package:bloc/bloc.dart';

// 6个关节状态
class MotorState {
  // 设备Id
  final List<int> ids = [21, 22, 23, 24, 25, 26];
  // 设备是否在线
  final List<bool> isOnline;
  // 角度
  final List<double> q;
  // 角速度
  final List<double> dq;
  // 加速度
  final List<double> ddq;
  // 力矩
  final List<double> T;

  // 修正构造函数赋值
  MotorState({
    required this.isOnline,
    required this.q,
    required this.dq,
    required this.ddq,
    required this.T,
  });

  // 提供一个初始状态的工厂方法
  factory MotorState.initial() => MotorState(
    isOnline: [false, false, false, false, false, false],
    q: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    dq: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    ddq: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    T: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  );

  MotorState copyWith({
    List<bool>? isOnline,
    List<double>? q,
    List<double>? dq,
    List<double>? ddq,
    List<double>? T,
  }) {
    return MotorState(
      isOnline: isOnline ?? List.from(this.isOnline),
      q: q ?? List.from(this.q),
      dq: dq ?? List.from(this.dq),
      ddq: ddq ?? List.from(this.ddq),
      T: T ?? List.from(this.T),
    );
  }
}

class MotorStateCubit extends Cubit<MotorState> {
  MotorStateCubit() : super(MotorState.initial());

  void setIsOnlines(List<bool> online) {
    emit(state.copyWith(isOnline: online));
  }

  void setIsOnline(int id, bool isOnline) {
    _updateById(
      id: id,
      values: state.isOnline,
      update: (list, index) {
        list[index] = isOnline;
      },
      setter: (list) => emit(state.copyWith(isOnline: list)),
    );
  }

  void setQs(List<double> q) {
    emit(state.copyWith(q: q));
  }

  void setQ(int id, double q) {
    _updateById(
      id: id,
      values: state.q,
      update: (list, index) {
        list[index] = q;
      },
      setter: (list) => emit(state.copyWith(q: list)),
    );
  }

  void setDqs(List<double> dq) {
    emit(state.copyWith(dq: dq));
  }

  void setDq(int id, double dq) {
    _updateById(
      id: id,
      values: state.dq,
      update: (list, index) {
        list[index] = dq;
      },
      setter: (list) => emit(state.copyWith(dq: list)),
    );
  }

  void setDdqs(List<double> ddq) {
    emit(state.copyWith(ddq: ddq));
  }

  void setDdq(int id, double ddq) {
    _updateById(
      id: id,
      values: state.ddq,
      update: (list, index) {
        list[index] = ddq;
      },
      setter: (list) => emit(state.copyWith(ddq: list)),
    );
  }

  void setTs(List<double> T) {
    emit(state.copyWith(T: T));
  }

  void setT(int id, double T) {
    _updateById(
      id: id,
      values: state.T,
      update: (list, index) {
        list[index] = T;
      },
      setter: (list) => emit(state.copyWith(T: list)),
    );
  }

  void _updateById<T>({
    required int id,
    required List<T> values,
    required void Function(List<T> list, int index) update,
    required void Function(List<T> list) setter,
  }) {
    final index = state.ids.indexOf(id);
    if (index == -1) return;

    final list = List<T>.from(values);
    update(list, index);
    setter(list);
  }
}
