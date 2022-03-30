import 'dart:convert';

import 'package:app/store/types/messageData.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:http/http.dart';

class MessageMarkdownPage extends StatefulWidget {
  MessageMarkdownPage({Key key}) : super(key: key);

  static final String route = '/profile/messageMarkdown';

  @override
  State<MessageMarkdownPage> createState() => _MessageMarkdownPageState();
}

class _MessageMarkdownPageState extends State<MessageMarkdownPage> {
  String _mdContent;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMd();
    });
    super.initState();
  }

  Future<void> _loadMd() async {
    final data = (ModalRoute.of(context).settings.arguments as MessageData);
    final Response res = await get(Uri.parse(data.detailUrl));
    String content = '';
    if (res != null) {
      content = utf8.decode(res.bodyBytes);
    }
    setState(() {
      _mdContent = content;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    return Scaffold(
        appBar: AppBar(
          title: Text(dic['message.community']),
          centerTitle: true,
          leading: BackBtn(),
        ),
        body: _mdContent == null
            ? Container(
                height: double.infinity,
                width: double.infinity,
                child: Center(
                  child: PluginLoadingWidget(),
                ),
              )
            : Markdown(data: _mdContent, selectable: true));
  }
}
