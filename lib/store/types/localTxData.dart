import 'package:json_annotation/json_annotation.dart';

part 'localTxData.g.dart';

@JsonSerializable()
class LocalTxData extends _LocalTxData {
  static LocalTxData fromJson(Map json) => _$LocalTxDataFromJson(json);
  static Map toJson(LocalTxData data) => _$LocalTxDataToJson(data);
}

abstract class _LocalTxData {
  String module;
  String call;
  List args;
  String hash;
  String blockHash;
  String eventId;
  int timestamp;
}
