// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'motions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Keyframe _$KeyframeFromJson(Map<String, dynamic> json) => Keyframe(
  name: json['name'] as String?,
  children: (json['children'] as List<dynamic>)
      .map((e) => KeyframeItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  time: (json['time'] as num?)?.toInt() ?? 0,
  createTime: json['createTime'] as String?,
);

Map<String, dynamic> _$KeyframeToJson(Keyframe instance) => <String, dynamic>{
  'name': instance.name,
  'children': instance.children,
  'time': instance.time,
  'createTime': instance.createTime,
};

Motion _$MotionFromJson(Map<String, dynamic> json) => Motion(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  createTime: json['createTime'] as String?,
  imgs: (json['imgs'] as List<dynamic>?)?.map((e) => e as String).toList(),
  coverImg: json['coverImg'] as String?,
  children: (json['children'] as List<dynamic>)
      .map((e) => Keyframe.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MotionToJson(Motion instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'imgs': instance.imgs,
  'coverImg': instance.coverImg,
  'children': instance.children,
  'createTime': instance.createTime,
};
