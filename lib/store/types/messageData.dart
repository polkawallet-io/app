import 'package:app/pages/profile/message/messageMarkdownPage.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:polkawallet_plugin_chainx/common/components/UI.dart';

part 'messageData.g.dart';

@JsonSerializable()
class MessageData {
  MessageData(this.id, this.banner, this.time, this.senderIcon, this.content,
      this.link, this.linkType, this.senderName, this.network, this.detailUrl);
  int id;
  String banner;
  String content;
  String link;
  String linkType;
  DateTime time;
  String senderIcon;
  String senderName;
  String network;
  String detailUrl;

  void onLinkAction(BuildContext context) {
    if (this.link.trim().length > 0) {
      this.linkType == 'url'
          ? UI.launchURL(this.link)
          : Navigator.of(context).pushNamed(this.link);
    }
  }

  void onDetailAction(BuildContext context) {
    if (this.detailUrl.trim().length > 0) {
      this.detailUrl.endsWith(".md")
          ? Navigator.of(context)
              .pushNamed(MessageMarkdownPage.route, arguments: this)
          : UI.launchURL(this.detailUrl);
    }
  }

  factory MessageData.fromJson(Map<String, dynamic> json) =>
      _$MessageDataFromJson(json);
  Map<String, dynamic> toJson() => _$MessageDataToJson(this);
}
