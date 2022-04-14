import 'package:app/pages/ecosystem/tokenStakingPage.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_ui/utils/format.dart';

class EcosystemPage extends StatelessWidget {
  const EcosystemPage({Key key}) : super(key: key);

  static final String route = '/ecosystem/ecosystem';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final TokenBalanceData balance = data["balance"];
    final convertNetwork = data["convertNetwork"];
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(dic['ecosystem.ecosystem']),
          centerTitle: true,
        ),
        body: SafeArea(
            child: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 36, right: 16, bottom: 5),
                    child: Image.asset("assets/images/complete_ecosystem.png"),
                  ),
                  Text(
                    dic['ecosystem.transactionCompleted'],
                    style: Theme.of(context)
                        .textTheme
                        .headline3
                        ?.copyWith(color: PluginColorsDark.headline1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 77, vertical: 10),
                    child: Text(
                      "${Fmt.priceFloorBigIntFormatter(Fmt.balanceInt(balance.amount), balance.decimals)} ${balance.symbol} ${dic['ecosystem.msg1']} ${convertNetwork} ${dic['ecosystem.msg2']}",
                      style: Theme.of(context)
                          .textTheme
                          .headline5
                          ?.copyWith(color: PluginColorsDark.headline1),
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.only(top: 9),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PluginOutlinedButtonSmall(
                            content: dic['ecosystem.backList'],
                            margin: EdgeInsets.only(right: 13),
                            padding: EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            color: PluginColorsDark.headline1,
                            fontSize: 16,
                            minSize: 34,
                            active: true,
                            onPressed: () => Navigator.of(context).popUntil(
                                (route) =>
                                    route.settings.name == TokenStaking.route),
                          ),
                          PluginOutlinedButtonSmall(
                            content: dic['ecosystem.seeTransaction'],
                            padding: EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            margin: EdgeInsets.zero,
                            color: PluginColorsDark.primary,
                            fontSize: 16,
                            minSize: 34,
                            active: true,
                            onPressed: () => Navigator.of(context).popUntil(
                                (route) =>
                                    route.settings.name == TokenStaking.route),
                          ),
                        ],
                      ))
                ],
              )),
        )));
  }
}
