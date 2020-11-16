// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transferData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferData _$TransferDataFromJson(Map<String, dynamic> json) {
  return TransferData()
    ..blockNum = json['block_num'] as int
    ..blockTimestamp = json['block_timestamp'] as int
    ..extrinsicIndex = json['extrinsic_index'] as String
    ..fee = json['fee'] as String
    ..from = json['from'] as String
    ..to = json['to'] as String
    ..amount = json['amount'] as String
    ..token = json['token'] as String
    ..hash = json['hash'] as String
    ..module = json['module'] as String
    ..success = json['success'] as bool;
}

Map<String, dynamic> _$TransferDataToJson(TransferData instance) =>
    <String, dynamic>{
      'block_num': instance.blockNum,
      'block_timestamp': instance.blockTimestamp,
      'extrinsic_index': instance.extrinsicIndex,
      'fee': instance.fee,
      'from': instance.from,
      'to': instance.to,
      'amount': instance.amount,
      'token': instance.token,
      'hash': instance.hash,
      'module': instance.module,
      'success': instance.success,
    };
