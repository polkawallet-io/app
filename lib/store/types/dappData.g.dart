// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dappData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DappData _$DappDataFromJson(Map<String, dynamic> json) {
  return DappData(json['icon'] as String, json['name'] as String,
      json['tag'] as List<dynamic>, json['detailUrl'] as String);
}

Map<String, dynamic> _$DappDataToJson(DappData instance) => <String, dynamic>{
      'icon': instance.icon,
      'name': instance.name,
      'tag': instance.tag,
      'detailUrl': instance.detailUrl
    };
