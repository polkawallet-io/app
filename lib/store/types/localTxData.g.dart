// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'localTxData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalTxData _$LocalTxDataFromJson(Map<String, dynamic> json) {
  return LocalTxData()
    ..module = json['module'] as String
    ..call = json['call'] as String
    ..args = json['args'] as List<dynamic>
    ..hash = json['hash'] as String
    ..blockHash = json['blockHash'] as String
    ..eventId = json['eventId'] as String
    ..timestamp = json['timestamp'] as int;
}

Map<String, dynamic> _$LocalTxDataToJson(LocalTxData instance) =>
    <String, dynamic>{
      'module': instance.module,
      'call': instance.call,
      'args': instance.args,
      'hash': instance.hash,
      'blockHash': instance.blockHash,
      'eventId': instance.eventId,
      'timestamp': instance.timestamp,
    };
