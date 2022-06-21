import 'package:app/pages/ecosystem/crosschainTransferPage.dart';
import 'package:app/pages/ecosystem/tokenStakingPage.dart';
import 'package:app/service/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_sdk/utils/app.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';

class EcosystemPage extends StatelessWidget {
  EcosystemPage(this.service, {Key key}) : super(key: key);
  AppService service;

  static final String route = '/ecosystem/ecosystem';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final TokenBalanceData balance = data["balance"];
    final convertNetwork = data["convertNetwork"];
    final type = data["type"];
    final banner = service.store.settings.adBanners['ecosystem'] as List;
    final transferBalance = data["transferBalance"] ?? "";
    final index = banner.indexWhere(
        (element) => element["network"] == service.plugin.basic.name);

    var plugin;
    if (service.plugin is PluginKarura) {
      plugin = service.plugin as PluginKarura;
    } else if (service.plugin is PluginAcala) {
      plugin = service.plugin as PluginAcala;
    }

    final tokensConfig = plugin.store.setting.remoteConfig['tokens'] ?? {};
    final tokenXcmConfig = List<String>.from(
        (tokensConfig['xcm'] ?? {})[balance.tokenNameId] ?? []);
    final tokenXcmFromConfig = List<String>.from(
        (tokensConfig['xcmFrom'] ?? {})[balance.tokenNameId] ?? []);
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
                      "${Fmt.priceFloorFormatter(double.parse(transferBalance))} ${balance.symbol} ${dic['ecosystem.msg1']} ${dic['ecosystem.$type']} $convertNetwork ${dic['ecosystem.msg2']}",
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
                            fontSize: UI.getTextSize(16, context),
                            minSize: 34,
                            active: true,
                            onPressed: () => Navigator.of(context).popUntil(
                                (route) =>
                                    route.settings.name == TokenStaking.route),
                          ),
                          Visibility(
                              visible: type == "transferred" ||
                                  (tokenXcmConfig.length > 0 &&
                                      convertNetwork ==
                                          service.plugin.basic.name) ||
                                  (tokenXcmFromConfig.length > 0 &&
                                      convertNetwork !=
                                          service.plugin.basic.name),
                              child: PluginOutlinedButtonSmall(
                                content: type == "transferred"
                                    ? dic['ecosystem.seeTransaction']
                                    : dic['ecosystem.crosschainTransfer'],
                                padding: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                margin: EdgeInsets.zero,
                                color: PluginColorsDark.primary,
                                fontSize: UI.getTextSize(16, context),
                                minSize: 34,
                                active: true,
                                onPressed: () {
                                  if (type == "transferred") {
                                    String networkName =
                                        service.plugin.basic.name;
                                    if (service.plugin.basic.isTestNet) {
                                      networkName =
                                          '${networkName.split('-')[0]}-testnet';
                                    }
                                    final snLink =
                                        'https://$networkName.subscan.io/account/${service.keyring.current.address}';
                                    UI.launchURL(snLink);
                                    Navigator.of(context).pop();
                                  } else {
                                    Navigator.of(context).popAndPushNamed(
                                        CrossChainTransferPage.route,
                                        arguments: {
                                          "balance": balance,
                                          "fromNetwork": convertNetwork
                                        });
                                  }
                                },
                              )),
                        ],
                      )),
                  Visibility(
                      visible: index >= 0,
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(top: 20),
                        child: index >= 0
                            ? GestureDetector(
                                child: CachedNetworkImage(
                                  width: double.infinity,
                                  imageUrl: banner[index]['banner'],
                                  placeholder: (context, url) =>
                                      PluginLoadingWidget(),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                onTap: () {
                                  final e = banner[index];
                                  if (e['isRoute'] == true) {
                                    final route = e['route'] as String;
                                    final network = e['routeNetwork'] as String;
                                    final args = e['routeArgs'] as Map;
                                    if (network != service.plugin.basic.name) {
                                      service.plugin.appUtils.switchNetwork(
                                        network,
                                        pageRoute:
                                            PageRouteParams(route, args: args),
                                      );
                                    } else {
                                      Navigator.of(context)
                                          .pushNamed(route, arguments: args);
                                    }
                                  } else if (e['isDapp'] == true) {
                                    Navigator.of(context).pushNamed(
                                      DAppWrapperPage.route,
                                      arguments: e['link'],
                                    );
                                  } else {
                                    UI.launchURL(e['link']);
                                  }
                                },
                              )
                            : Container(),
                      ))
                ],
              )),
        )));
  }
}
