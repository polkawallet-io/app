import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class BridgePageParams {
  BridgePageParams(this.chainFrom, this.chainTo, this.token, this.address);
  final String chainFrom;
  final String chainTo;
  final String token;
  final String address;

  factory BridgePageParams.fromJson(Map<String, dynamic> json) {
    return BridgePageParams(
        json['chainFrom'] as String,
        json['chainTo'] as String,
        json['token'] as String,
        json['address'] as String);
  }
}
