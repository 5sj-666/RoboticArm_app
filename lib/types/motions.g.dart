// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'motions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Keyframe _$KeyframeFromJson(Map<String, dynamic> json) => Keyframe(
  name: json['name'] as String?,
  positions: (json['positions'] as List<dynamic>)
      .map((e) => (e as num).toDouble())
      .toList(),
  time: (json['time'] as num?)?.toDouble() ?? 0.0,
  createTime: json['createTime'] as String?,
  timingFunction: json['timingFunction'] as String?,
);

Map<String, dynamic> _$KeyframeToJson(Keyframe instance) => <String, dynamic>{
  'name': instance.name,
  'positions': instance.positions,
  'time': instance.time,
  'createTime': instance.createTime,
  'timingFunction': instance.timingFunction,
};

Motion _$MotionFromJson(Map<String, dynamic> json) => Motion(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  createTime: json['createTime'] as String?,
  imgs: (json['imgs'] as List<dynamic>?)?.map((e) => e as String).toList(),
  coverImg: json['coverImg'] as String?,
  keyframes: (json['keyframes'] as List<dynamic>)
      .map((e) => Keyframe.fromJson(e as Map<String, dynamic>))
      .toList(),
  author: json['author'] as String?,
  faverite: (json['faverite'] as num?)?.toInt(),
);

Map<String, dynamic> _$MotionToJson(Motion instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'imgs': instance.imgs,
  'coverImg': instance.coverImg,
  'keyframes': instance.keyframes,
  'createTime': instance.createTime,
  'author': instance.author,
  'faverite': instance.faverite,
};
