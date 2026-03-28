import 'package:json_annotation/json_annotation.dart';
part 'motions.g.dart';

Map<String, int> jointIdMap = {
  'joint1': 21,
  'joint2': 22,
  'joint3': 23,
  'joint4': 24,
  'joint5': 25,
  'joint6': 26,
};

// 关节的关键帧集合
@JsonSerializable()
class Keyframe {
  String? name; // 保存至本地存储的标题 关键帧标题 kf + 用户输入的标题
  List<double> positions;
  double time; // 秒 帧运行耗费的时间
  String? createTime; // 创建时间(时间戳)
  String? timingFunction = '.1,.1,.9,.9';
  int repeatCount = 0;
  double markerTimeStart = 0.0; // 时间轴上标记的位置（在时间轴上的哪一时刻开始运行），单位为秒
  double markerTimeEnd = 0.0; // 时间轴上标记的位置（在时间轴上的哪一时刻结束运行），单位为秒

  Keyframe({
    this.name,
    required this.positions,
    this.time = 0.0,
    this.createTime,
    this.timingFunction,
    this.repeatCount = 0,
    this.markerTimeStart = 0.0,
    this.markerTimeEnd = 0.0,
  });

  factory Keyframe.fromJson(Map<String, dynamic> json) =>
      _$KeyframeFromJson(json);
  Map<String, dynamic> toJson() => _$KeyframeToJson(this);
}

// motion则是由多个keyframe组合而成，
@JsonSerializable()
class Motion {
  String id; // 时间戳 + 随机数
  String name; // 存储在sharedreferences动作名称 motion_ 作为前缀
  String description; // 动作描述
  List<String>? imgs; // 图片地址列表
  String? coverImg; //封面地址
  List<Keyframe> keyframes; // 关键帧列表
  String? createTime;
  String? author;
  int? faverite;

  Motion({
    required this.id,
    required this.name,
    required this.description,
    this.createTime,
    this.imgs,
    this.coverImg,
    required this.keyframes,
    this.author,
    this.faverite,
  });

  Map<String, dynamic> toJson() => _$MotionToJson(this);

  factory Motion.fromJson(Map<String, dynamic> json) => _$MotionFromJson(json);
}
