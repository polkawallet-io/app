// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messageData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageData _$MessageDataFromJson(Map<String, dynamic> json) {
  return MessageData(
    json['file'] as String,
    json['banner'] as String,
    DateTime.parse((json['time'] as String).replaceAll("/", "-")),
    json['title'] as String,
    json['network'] as String,
    json['lang'] as String,
    json['content'] as String,
  );
}

Map<String, dynamic> _$MessageDataToJson(MessageData instance) =>
    <String, dynamic>{
      'file': instance.file,
      'banner': instance.banner,
      'title': instance.title,
      'time': instance.time.toIso8601String(),
      'network': instance.network,
      'lang': instance.lang,
      'content': instance.content,
    };
