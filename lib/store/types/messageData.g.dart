// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messageData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageData _$MessageDataFromJson(Map<String, dynamic> json) {
  return MessageData(
    json['id'] as int,
    json['banner'] as String,
    DateTime.parse(json['time'] as String),
    json['senderIcon'] as String,
    json['content'] as String,
    json['link'] as String,
    json['linkType'] as String,
    json['senderName'] as String,
    json['network'] as String,
    json['detailUrl'] as String,
  );
}

Map<String, dynamic> _$MessageDataToJson(MessageData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'banner': instance.banner,
      'content': instance.content,
      'link': instance.link,
      'linkType': instance.linkType,
      'time': instance.time.toIso8601String(),
      'senderIcon': instance.senderIcon,
      'senderName': instance.senderName,
      'network': instance.network,
      'detailUrl': instance.detailUrl,
    };
