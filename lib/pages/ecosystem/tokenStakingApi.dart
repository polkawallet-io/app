import 'package:app/service/index.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';

class TokenStakingApi {
  static Map<String, Map<String, TokenBalanceData>> balances = {};

  static Function refresh;

  static Map<String, dynamic> _cacheTokenStakingAssets;

  static Map<String, TokenBalanceData> formatBalanceData(
      AppService service, List<dynamic> networkNames, String token,
      {Map<String, TokenBalanceData> balances = const {},
      bool isCacheChange = true}) {
    dynamic plugin;
    if (service.plugin is PluginKarura) {
      plugin = service.plugin as PluginKarura;
    } else if (service.plugin is PluginAcala) {
      plugin = service.plugin as PluginAcala;
    }

    final TokenBalanceData currentPluginBalance =
        plugin.store.assets.tokenBalanceMap[token];
    if (networkNames.isEmpty) {
      TokenStakingApi.balances[token] = {
        service.plugin.basic.name: currentPluginBalance
      };
      return {service.plugin.basic.name: currentPluginBalance};
    }

    _cacheTokenStakingAssets ??=
        service.bridge.getTokenStakingAssets(service.keyring.current.pubKey) ??
            {};

    for (int i = 0; i < networkNames.length; i++) {
      final element = networkNames[i];

      if (balances[element] != null) {
        _cacheTokenStakingAssets["$element-$token"] = {
          "amount": balances[element].amount
        };
      }
    }

    if (_cacheTokenStakingAssets["${service.plugin.basic.name}-$token"] !=
            null &&
        _cacheTokenStakingAssets["${service.plugin.basic.name}-$token"] !=
            currentPluginBalance.amount &&
        isCacheChange) {
      currentPluginBalance.isCacheChange = true;
    } else {
      currentPluginBalance.isCacheChange = false;
    }

    _cacheTokenStakingAssets["${service.plugin.basic.name}-$token"] =
        currentPluginBalance.amount;

    service.bridge.setTokenStakingAssets(
        service.keyring.current.pubKey, _cacheTokenStakingAssets);

    final datas = <String, TokenBalanceData>{}
      ..addAll({service.plugin.basic.name: currentPluginBalance})
      ..addAll(balances);

    if (TokenStakingApi.balances[token] == null) {
      TokenStakingApi.balances[token] = datas;
    } else {
      TokenStakingApi.balances[token].addAll(datas);
    }
    if (!isCacheChange && TokenStakingApi.refresh != null) {
      TokenStakingApi.refresh();
    }
    return datas;
  }
}
