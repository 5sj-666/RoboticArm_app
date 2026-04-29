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
  time: (json['time'] as num?)?.toDouble() ?? 0,
  createTime: json['createTime'] as String?,
  timingFunction: json['timingFunction'] as String?,
  repeatCount: (json['repeatCount'] as num?)?.toInt() ?? 0,
  markerTimeStart: (json['markerTimeStart'] as num?)?.toDouble() ?? 0.0,
  markerTimeEnd: (json['markerTimeEnd'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$KeyframeToJson(Keyframe instance) => <String, dynamic>{
  'name': instance.name,
  'positions': instance.positions,
  'time': instance.time,
  'createTime': instance.createTime,
  'timingFunction': instance.timingFunction,
  'repeatCount': instance.repeatCount,
  'markerTimeStart': instance.markerTimeStart,
  'markerTimeEnd': instance.markerTimeEnd,
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
  nodes: (json['nodes'] as List<dynamic>?)
      ?.map(
        (e) => (e as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      )
      .toList(),
  author: json['author'] as String?,
  favorite: (json['favorite'] as num?)?.toInt(),
  timingFunc: json['timingFunc'] as String?,
  time: (json['time'] as num?)?.toDouble(),
);

Map<String, dynamic> _$MotionToJson(Motion instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'imgs': instance.imgs,
  'coverImg': instance.coverImg,
  'keyframes': instance.keyframes,
  'nodes': instance.nodes,
  'createTime': instance.createTime,
  'author': instance.author,
  'favorite': instance.favorite,
  'timingFunc': instance.timingFunc,
  'time': instance.time,
};
