import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:polkawallet_plugin_chainx/common/components/UI.dart';

part 'messageData.g.dart';

@JsonSerializable()
class MessageData {
  MessageData(
      this.id,
      this.banner,
      this.time,
      this.senderIcon,
      this.title,
      this.content,
      this.link,
      this.linkType,
      this.senderName,
      this.network,
      this.detailUrl);
  int id;
  String banner;
  String title;
  String content;
  String link;
  String linkType;
  DateTime time;
  String senderIcon;
  String senderName;
  String network;
  String detailUrl;

  void onLinkAction(BuildContext context) {
    this.linkType == 'url'
        ? UI.launchURL(this.link)
        : Navigator.of(context).pushNamed(this.link);
  }

  factory MessageData.fromJson(Map<String, dynamic> json) =>
      _$MessageDataFromJson(json);
  Map<String, dynamic> toJson() => _$MessageDataToJson(this);
}
