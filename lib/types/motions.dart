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
// 具体关键帧
class Keyframe {
  int time; // 毫秒
  double location; // 位置
  String timingFunction; // 贝塞尔曲线控制点 "0,0,1,1"
  int motorId; // 电机ID

  Keyframe({
    required this.time,
    required this.location,
    required this.timingFunction,
    required this.motorId,
  });
}

// 关节的关键帧集合
class Keyframes {
  String name; // 关节名称
  int motorId; // 电机ID
  List<Keyframe> keyframes; // 关键帧列表

  Keyframes({
    required this.name,
    required this.motorId,
    required this.keyframes,
  });
}

class Motion {
  String id; // 时间戳 + 随机数
  String name; // 动作名称
  String description; // 动作描述
  List<Keyframes> joints;

  Motion({
    required this.id,
    required this.name,
    required this.description,
    required this.joints,
  });
}
