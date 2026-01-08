import 'package:bloc/bloc.dart';
import 'package:robotic_arm_app/utils/motorMsgParse.dart';

class MotorLog {
  // 原指令
  final List<int> cmd;
  final String role; // S: sender.  R: Receiver
  final String parseMsg; // 解析后的信息
  final String timeStamp;
  // final String success; // 是否发送成功

  MotorLog({
    required this.cmd,
    required this.role,
    required this.parseMsg,
    required this.timeStamp,
  });
}

class MotorLogState {
  final List<MotorLog> list;
  MotorLogState({this.list = const []});
}

class MotorLogCubit extends Cubit<MotorLogState> {
  MotorLogCubit() : super(MotorLogState());

  void addLog({required List<int> cmd, String role = 'S'}) {
    final result = parseCmd(cmd);
    late MotorLog msg;
    if (result == null) {
      msg = MotorLog(
        cmd: cmd,
        role: role,
        parseMsg: cmd.toString(),
        timeStamp: '',
      );
    } else {
      msg = MotorLog(
        cmd: result['rawCmd'],
        role: role,
        parseMsg: result['parseStr'],
        timeStamp: '',
      );
    }

    // 创建一个新的状态对象
    final updatedList = List<MotorLog>.from(state.list)..add(msg);
    emit(MotorLogState(list: updatedList));
  }

  void clearLog() {
    emit(MotorLogState(list: []));
  }
}
