import 'package:json_annotation/json_annotation.dart';

part 'dappData.g.dart';

@JsonSerializable()
class DappData {
  DappData(this.icon, this.name, this.tag, this.detailUrl);
  String icon;
  String name;
  List<dynamic> tag;
  String detailUrl;

  factory DappData.fromJson(Map<String, dynamic> json) =>
      _$DappDataFromJson(json);
  Map<String, dynamic> toJson() => _$DappDataToJson(this);
}
