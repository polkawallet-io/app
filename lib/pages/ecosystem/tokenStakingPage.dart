import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:app/pages/ecosystem/crosschainTransferPage.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_kusama/polkawallet_plugin_kusama.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPageTitleTaps.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/consts.dart';

class TokenStaking extends StatefulWidget {
  TokenStaking({Key key}) : super(key: key);

  static final String route = '/ecosystem/tokenStaking';

  @override
  State<TokenStaking> createState() => _TokenStakingState();
}

class _TokenStakingState extends State<TokenStaking> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final String token = data["token"];
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text("${token.toUpperCase()} ${dic['hub.staking']}"),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(16, 16, 0, 16),
                child: PluginPageTitleTaps(
                  names: [token.toUpperCase(), "L${token.toUpperCase()}"],
                  itemPadding:
                      EdgeInsets.symmetric(vertical: 3, horizontal: 40),
                  activeTab: _tab,
                  onTap: (i) {
                    setState(() {
                      _tab = i;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Color(0x1affffff),
                  child: ListView.separated(
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final plugin = PluginKusama();
                      return TokenItemView(
                          plugin.basic.name,
                          plugin.basic.icon,
                          _tab == 0 ? token : "L$token",
                          100,
                          _tab == 1 ? token : "L$token");
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        color: Color(0xFFFFFFFF).withAlpha(36),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}

class TokenItemView extends StatefulWidget {
  TokenItemView(
      this.name, this.icon, this.token, this.amount, this.convertToKen,
      {Key key})
      : super(key: key);
  String name;
  String token;
  String convertToKen;
  Widget icon;
  double amount;

  @override
  State<TokenItemView> createState() => _TokenItemViewState();
}

class _TokenItemViewState extends State<TokenItemView> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final style = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(fontWeight: FontWeight.w600, color: Colors.white);
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _isOpen = !_isOpen;
          });
        },
        child: Container(
          padding: EdgeInsets.only(left: 16, right: 32),
          child: Column(
            children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Padding(
                            child: SizedBox(
                                child: widget.icon, height: 32, width: 32),
                            padding: EdgeInsets.only(right: 10),
                          ),
                          Text(
                            "${dic['ecosystem.on']} ${widget.name}",
                            style: style,
                          )
                        ],
                      ),
                      Text(
                          "${Fmt.priceFloorFormatter(widget.amount)} ${widget.token.toUpperCase()}",
                          style: style)
                    ],
                  )),
              Visibility(
                  visible: _isOpen,
                  child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          PluginOutlinedButtonSmall(
                            content: dic['ecosystem.crosschainTransfer'],
                            padding: EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            color: PluginColorsDark.primary,
                            fontSize: 12,
                            minSize: 25,
                            active: true,
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                  CrosschainTransferPage.route,
                                  arguments: {
                                    "token": widget.token,
                                    "fromNetwork": widget.name,
                                    "amount": widget.amount
                                  });
                            },
                          ),
                          PluginOutlinedButtonSmall(
                            content:
                                "${dic['ecosystem.convertTo']} ${widget.convertToKen.toUpperCase()}",
                            padding: EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            margin: EdgeInsets.zero,
                            color: PluginColorsDark.headline1,
                            fontSize: 12,
                            minSize: 25,
                            active: true,
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(ConverToPage.route, arguments: {
                                "token": widget.token,
                                "fromNetwork": widget.name,
                                "amount": widget.amount
                              });
                            },
                          ),
                        ],
                      )))
            ],
          ),
        ));
  }
}
