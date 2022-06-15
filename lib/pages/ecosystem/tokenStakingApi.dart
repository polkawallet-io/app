import 'package:app/service/index.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';

class TokenStakingApi {
  static Map<String, Map<String, TokenBalanceData>> balances =
      Map<String, Map<String, TokenBalanceData>>();

  static Function refresh;

  static Future<Map<String, TokenBalanceData>> getBalance(
      AppService service, List<dynamic> networkNames, String token,
      {bool isCachaChange = true}) async {
    if (networkNames.length == 0) {
      TokenStakingApi.balances[token] = {};
      return {};
    }

    var plugin;
    if (service.plugin is PluginKarura) {
      plugin = service.plugin as PluginKarura;
    } else if (service.plugin is PluginAcala) {
      plugin = service.plugin as PluginAcala;
    }

    final TokenBalanceData currentPluginBalance =
        plugin.store.assets.tokenBalanceMap[token];

    Map<String, TokenBalanceData> balances = Map<String, TokenBalanceData>();
    var cacheTokenStakingAssets =
        service.assets.getTokenStakingAssets(service.keyring.current.pubKey) ??
            Map<String, dynamic>();
    final fromChainBalances = await Future.wait(networkNames
        .map((e) => service.plugin.sdk.webView.evalJavascript(
            'xcm.getBalances("$e", "${service.keyring.current.address}", ["$token"])'))
        .toList());
    for (int i = 0; i < networkNames.length; i++) {
      final element = networkNames[i];
      final data = fromChainBalances[i];
      if (data != null) {
        final balance = List.of(data)[0];
        if (balance != null) {
          final balanceData = TokenBalanceData(
              tokenNameId: balance['tokenNameId'],
              amount: balance['amount'],
              decimals: balance['decimals'],
              symbol: token,
              minBalance: currentPluginBalance.minBalance,
              name: token,
              currencyId: {'Token': token},
              detailPageRoute: "/assets/token/detail",
              isCacheChange: cacheTokenStakingAssets == null ||
                      cacheTokenStakingAssets["$element-$token"] == null ||
                      isCachaChange == false
                  ? false
                  : cacheTokenStakingAssets["$element-$token"]['amount'] !=
                      balance['amount']);

          balances[element] = balanceData;
          cacheTokenStakingAssets["$element-$token"] = {
            "amount": balance['amount']
          };
        }
      }
    }

    if (cacheTokenStakingAssets["${service.plugin.basic.name}-$token"] !=
            null &&
        cacheTokenStakingAssets["${service.plugin.basic.name}-$token"] !=
            currentPluginBalance.amount &&
        isCachaChange) {
      currentPluginBalance.isCacheChange = true;
    }
    cacheTokenStakingAssets["${service.plugin.basic.name}-$token"] =
        currentPluginBalance.amount;

    service.assets.setTokenStakingAssets(
        service.keyring.current.pubKey, cacheTokenStakingAssets);

    final datas = Map<String, TokenBalanceData>()
      ..addAll({service.plugin.basic.name: currentPluginBalance})
      ..addAll(balances);

    if (TokenStakingApi.balances[token] == null) {
      TokenStakingApi.balances[token] = datas;
    } else {
      TokenStakingApi.balances[token].addAll(datas);
    }
    if (!isCachaChange && TokenStakingApi.refresh != null) {
      TokenStakingApi.refresh();
    }
    return datas;
  }
}
