import 'package:app/service/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/ui.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';

class PluginPage extends StatefulWidget {
  PluginPage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static final String route = '/pluginPage';

  @override
  _PluginPageState createState() => _PluginPageState();
}

class _PluginPageState extends State<PluginPage> {
  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context).settings.arguments as Map;
    // return PluginScaffold(
    //     appBar: PluginAppBar(
    //       title: Text(data['title']),
    //     ),
    //     body: data['body']);
    return Scaffold(
        appBar: AppBar(
          title: Text(data['title']),
          centerTitle: true,
          leading: BackBtn(),
        ),
        body: PageWrapperWithBackground(
          data['body'],
          height: 220,
          backgroundImage: widget.service.plugin.basic.backgroundImage,
        ));
  }
}
