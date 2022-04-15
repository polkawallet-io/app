import 'dart:convert';

import 'package:app/pages/ecosystem/tokenStakingPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class CompletedPage extends StatefulWidget {
  CompletedPage(this.service, {Key key}) : super(key: key);
  AppService service;

  static final String route = '/ecosystem/completed';
  @override
  State<CompletedPage> createState() => _CompletedPageState();
}

class _CompletedPageState extends State<CompletedPage> {
  bool _connecting = false;
  Map<String, TokenBalanceData> _balances;

  _getBalance(List<String> networkNames) async {
    final connected = await widget.service.plugin.sdk.webView
        .evalJavascript('xcm.connectFromChain(${json.encode(networkNames)})');
    Map<String, TokenBalanceData> balances = Map<String, TokenBalanceData>();
    if (connected != null) {
      final data = ModalRoute.of(context).settings.arguments as Map;
      final TokenBalanceData balance = data["balance"];
      for (int i = 0; i < networkNames.length; i++) {
        final element = networkNames[i];
        final data = await widget.service.plugin.sdk.webView.evalJavascript(
            'xcm.getBalances("$element", "${widget.service.keyring.current.address}", ["${balance.symbol}"])');
        if (data != null) {
          final balanceVar = List.of(data)[0];
          if (balanceVar != null) {
            final balanceData = TokenBalanceData(
              tokenNameId: balanceVar['tokenNameId'],
              amount: balanceVar['amount'],
              decimals: balanceVar['decimals'],
              symbol: balance.symbol,
            );
            balances[element] = balanceData;
          }
        }
      }
    }
    var plugin;
    if (widget.service.plugin is PluginKarura) {
      plugin = widget.service.plugin as PluginKarura;
    } else if (widget.service.plugin is PluginAcala) {
      plugin = widget.service.plugin as PluginAcala;
    }
    if (plugin != null) {
      final data = ModalRoute.of(context).settings.arguments as Map;
      final TokenBalanceData balance = data["balance"];
      plugin.service.assets.updateTokenBalances(balance);
    }
    setState(() {
      _connecting = true;
      _balances = balances;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ModalRoute.of(context).settings.arguments as Map;
      final fromNetwork = data["fromNetwork"];
      _getBalance([fromNetwork]);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final TokenBalanceData balance = data["balance"];
    final fromNetwork = data["fromNetwork"];
    final String convertToKen = data["convertToKen"];
    final _fee = data["fee"];

    final style = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(color: PluginColorsDark.headline1, height: 2.0);

    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(dic['ecosystem.completed']),
          centerTitle: true,
        ),
        body: Observer(builder: (_) {
          final currentBalance = widget.service.plugin.noneNativeTokensAll
              .firstWhere((element) => element.symbol == balance.symbol);
          return SafeArea(
              child: _connecting == false
                  ? Container(
                      height: double.infinity,
                      width: double.infinity,
                      child: Center(
                        child: PluginLoadingWidget(),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            margin:
                                EdgeInsets.only(top: 16, bottom: 16, left: 16),
                            width: double.infinity,
                            child: Image.asset("assets/images/completed.png"),
                          ),
                          Text(
                            dic['ecosystem.completed'],
                            style: Theme.of(context)
                                .textTheme
                                .headline2
                                ?.copyWith(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: PluginColorsDark.headline1),
                          ),
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                InfoItemRow(
                                  "${dic['ecosystem.on']} ${widget.service.plugin.basic.name}",
                                  "${Fmt.priceFloorBigIntFormatter(Fmt.balanceInt(currentBalance.amount), currentBalance.decimals)} ${currentBalance.symbol}",
                                  labelStyle: style,
                                  contentStyle: style,
                                ),
                                InfoItemRow(
                                  "${dic['ecosystem.on']} $fromNetwork",
                                  "${Fmt.priceFloorBigIntFormatter(Fmt.balanceInt(_balances[fromNetwork].amount), balance.decimals)} ${balance.symbol}",
                                  labelStyle: style,
                                  contentStyle: style,
                                ),
                                InfoItemRow(
                                  I18n.of(context).getDic(i18n_full_dic_karura,
                                      'acala')['transfer.fee'],
                                  '${Fmt.priceCeilBigInt(Fmt.balanceInt(_fee), balance.decimals, lengthMax: 6)} ${balance.symbol}',
                                  labelStyle: style,
                                  contentStyle: style,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 75),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: PluginButton(
                                          title: dic['ecosystem.backList'],
                                          onPressed: () => Navigator.of(context)
                                              .popUntil((route) =>
                                                  route.settings.name ==
                                                  TokenStaking.route),
                                        ),
                                      ),
                                      Container(
                                        width: 16,
                                      ),
                                      Expanded(
                                        child: PluginButton(
                                          backgroundColor:
                                              PluginColorsDark.headline1,
                                          title:
                                              "${dic['ecosystem.convertTo']} $convertToKen",
                                          onPressed: () {
                                            if (convertToKen.startsWith("L")) {
                                              //to mint
                                              Navigator.of(context).pushNamed(
                                                  "/${widget.service.plugin.basic.name.toLowerCase()}/homa/mint");
                                            } else {
                                              //to redeem
                                              Navigator.of(context).pushNamed(
                                                  "/${widget.service.plugin.basic.name.toLowerCase()}/homa/redeem");
                                            }
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ));
        }));
  }
}