import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AnnouncePageParams {
  AnnouncePageParams({this.title, this.link});
  final String title;
  final String link;
}

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({Key key}) : super(key: key);
  static String route = '/announce';

  @override
  _AnnouncementPageState createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  WebViewController controller;

  @override
  void initState() {
    super.initState();

    final AnnouncePageParams params = ModalRoute.of(context).settings.arguments;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(params.link));
  }

  @override
  Widget build(BuildContext context) {
    final Map dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    return Scaffold(
      appBar: AppBar(
          title: Text(dic['announce']), centerTitle: true, leading: BackBtn()),
      body: SafeArea(
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}
