import 'package:json_annotation/json_annotation.dart';

part 'motions.g.dart';

class Joints {
  final double joint1;
  final double joint2;
  final double joint3;
  final double joint4;
  final double joint5;
  final double joint6;

  const Joints({
    this.joint1 = 0.0,
    this.joint2 = 0.0,
    this.joint3 = 0.0,
    this.joint4 = 0.0,
    this.joint5 = 0.0,
    this.joint6 = 0.0,
  });

  Joints copyWith({
    double? joint1,
    double? joint2,
    double? joint3,
    double? joint4,
    double? joint5,
    double? joint6,
  }) {
    return Joints(
      joint1: joint1 ?? this.joint1,
      joint2: joint2 ?? this.joint2,
      joint3: joint3 ?? this.joint3,
      joint4: joint4 ?? this.joint4,
      joint5: joint5 ?? this.joint5,
      joint6: joint6 ?? this.joint6,
    );
  }

  Joints.fromJson(Map<String, dynamic> json)
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

Map<String, int> jointIdMap = {
  'joint1': 21,
  'joint2': 22,
  'joint3': 23,
  'joint4': 24,
  'joint5': 25,
  'joint6': 26,
};
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

// 具体某个关节的关键帧
///int time; // 毫秒
/// double location; // 位置
///String timingFunction; // 贝塞尔曲线控制点 "0,0,1,1"
///int motorId; // 电机ID
class KeyframeItem {
  int? time; // 毫秒
  double? location; // 位置
  String? timingFunction; // 贝塞尔曲线控制点 "0,0,1,1"
  int? motorId; // 电机ID

  KeyframeItem({
    this.time = 0,
    this.location,
    this.timingFunction = 'linear',
    this.motorId,
  });

  Map<String, dynamic> toJson() => {
    'time': time,
    'location': location,
    'timingFunction': timingFunction,
    'motorId': motorId,
  };

  KeyframeItem.fromJson(Map<String, dynamic> json)
    : time = json['time'] as int,
      location = json['location'] as double,
      timingFunction = json['timingFunction'] as String,
      motorId = json['motorId'] as int;

  //       int? time; // 毫秒
  // double? location; // 位置
  // String? timingFunction; // 贝塞尔曲线控制点 "0,0,1,1"
  // int? motorId; // 电
}

// 关节的关键帧集合
@JsonSerializable()
class Keyframe {
  String? name; // 保存至本地存储的标题 关键帧标题 kf + 用户输入的标题
  // int motorId; // 电机ID
  List<KeyframeItem> children; // 关键帧列表
  int time; // 毫秒
  String? createTime; // 创建时间 用intl格式化为字符串类型

  Keyframe({
    this.name,
    // required this.motorId,
    required this.children,
    this.time = 0,
    this.createTime,
  });

  factory Keyframe.fromJson(Map<String, dynamic> json) =>
      _$KeyframeFromJson(json);
  Map<String, dynamic> toJson() => _$KeyframeToJson(this);

  // Map<String, dynamic> toJson() =>
  // factory Keyframe.fromJson(Map<String, dynamic> json) {
  //   final List<KeyframeItem> childrenList =
  //       (json['children'] as List<dynamic>?)
  //           ?.map((e) => KeyframeItem.fromJson(e as Map<String, dynamic>))
  //           .toList() ??
  //       <KeyframeItem>[];

  //   final int parsedTime = (json['time'] is num)
  //       ? (json['time'] as num).toInt()
  //       : int.tryParse('${json['time']}') ?? 0;

  //   return Keyframe(
  //     name: json['name']?.toString(),
  //     children: childrenList,
  //     time: parsedTime,
  //     createTime: json['createTime']?.toString(),
  //   );
  // }

  //    List<KeyframeItem> children; // 关键帧列表
  // int time; // 毫秒
  // String? createTi

  // Map<String, dynamic> toJson() => {
  //   'name': name,
  //   'time': time,
  //   'createTime': createTime,
  //   'children': children,
  // };
}

// motion则是由多个keyframe组合而成，
@JsonSerializable()
class Motion {
  String id; // 时间戳 + 随机数
  String name; // 存储在sharedreferences动作名称 motion_ 作为前缀
  String description; // 动作描述
  List<String>? imgs; // 图片地址列表
  String? coverImg; //封面地址
  List<Keyframe> children; // 关键帧列表
  String? createTime;

  Motion({
    required this.id,
    required this.name,
    required this.description,
    this.createTime,
    this.imgs,
    this.coverImg,
    required this.children,
  });

  Map<String, dynamic> toJson() => _$MotionToJson(this);
  // Map<String, dynamic> toJson() => {
  //       'id': id,
  //       'name': name,
  //       'description': description,
  //       'createTime': createTime,
  //       'imgs': imgs,
  //       'coverImg': coverImg,
  //       'children': children,
  //     };
  factory Motion.fromJson(Map<String, dynamic> json) => _$MotionFromJson(json);
  // factory Motion.fromJson(Map<String, dynamic> json) {
  //   final List<Keyframe> childrenList = (json['children'] as List<dynamic>?)
  //           ?.map((e) => Keyframe.fromJson(e as Map<String, dynamic>))
  //           .toList() ??
  //       <Keyframe>[];

  //   return Motion(
  //     id: json['id'],
  //     name: json['name'],
  //     description: json['description'],
  //     createTime: json['createTime'],
  //     imgs: json['imgs'],
  //     coverImg: json['coverImg'],
  //     children: childrenList,
  //   );
  // }
}

/// 根据关节的位置信息生成关键帧
/// 便利关节位置信息，
// Keyframe generateKeyfreme(Joints positions, String inputName) {
//   final positionMap = positions.toJson();
//   DateTime createTime = DateTime.now();
//   final keyframe =
//       Keyframe(name: inputName, createTime: createTime, children: []);
//   positionMap.forEach((key, value) {
//     print('$key: $value');
//     final item = KeyframeItem(location: value, motorId: jointIdMap[key]);
//     keyframe.children.add(item);
//   });

//   return keyframe;
// }

/// 想法： Motion存本地的数据是{name: xxx, children: [keyframe_name1,keyframe_name2]};
///keyframe_name是关键帧的名称
