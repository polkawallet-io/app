import 'package:app/pages/ecosystem/tokenStakingPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';
import 'package:polkawallet_ui/utils/consts.dart';

class CompletedPage extends StatelessWidget {
  CompletedPage(this.service, {Key key}) : super(key: key);
  AppService service;

  static final String route = '/ecosystem/completed';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final String token = data["token"];
    final fromNetwork = data["fromNetwork"];
    final amount = data["amount"];
    final String convertToKen = data["convertToKen"];

    final style = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(color: PluginColorsDark.headline1, height: 2.0);
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(dic['ecosystem.completed']),
          centerTitle: true,
        ),
        body: SafeArea(
            child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 16, bottom: 16, left: 16),
                width: double.infinity,
                child: Image.asset("assets/images/completed.png"),
              ),
              Text(
                dic['ecosystem.completed'],
                style: Theme.of(context).textTheme.headline2?.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: PluginColorsDark.headline1),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    InfoItemRow(
                      "${dic['ecosystem.on']} ${service.plugin.basic.name}",
                      "$amount ${token.toUpperCase()}",
                      labelStyle: style,
                      contentStyle: style,
                    ),
                    InfoItemRow(
                      "${dic['ecosystem.on']} $fromNetwork",
                      "$amount ${token.toUpperCase()}",
                      labelStyle: style,
                      contentStyle: style,
                    ),
                    InfoItemRow(
                      "Network Fee",
                      "0.2 ${token.toUpperCase()}",
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
                              onPressed: () => Navigator.of(context).popUntil(
                                  (route) =>
                                      route.settings.name ==
                                      TokenStaking.route),
                            ),
                          ),
                          Container(
                            width: 16,
                          ),
                          Expanded(
                            child: PluginButton(
                              backgroundColor: PluginColorsDark.headline1,
                              title:
                                  "${dic['ecosystem.convertTo']} ${convertToKen.toUpperCase()}",
                              onPressed: () {
                                if (convertToKen.startsWith("L")) {
                                  //to redeem
                                  Navigator.of(context).pushNamed(
                                      "/${service.plugin.basic.name.toLowerCase()}/homa/redeem");
                                } else {
                                  //to mint
                                  Navigator.of(context).pushNamed(
                                      "/${service.plugin.basic.name.toLowerCase()}/homa/mint");
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
        )));
  }
}
