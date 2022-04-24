import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';

class TokenStaking extends StatefulWidget {
  TokenStaking({Key key}) : super(key: key);

  static final String route = '/ecosystem/tokenStaking';

  @override
  State<TokenStaking> createState() => _TokenStakingState();
}

class _TokenStakingState extends State<TokenStaking> {
  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final token = data["token"];
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text("${token.toUpperCase()} ${dic['hub.staking']}"),
          centerTitle: true,
        ),
        body: Container());
  }
}
