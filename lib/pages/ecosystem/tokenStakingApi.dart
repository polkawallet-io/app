import 'package:app/service/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';

class TokenStakingApi {
  static Map<String, Map<String, TokenBalanceData>> balances = {};

  static Function refresh;

  static Map<String, dynamic> _cacheTokenStakingAssets;

  static Map<String, TokenBalanceData> formatBalanceData(
      AppService service, List<dynamic> networkNames, String token,
      {Map<String, TokenBalanceData> balances = const {}}) {
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

    final currentPluginBalance = balances[service.plugin.basic.name];

    _cacheTokenStakingAssets["${service.plugin.basic.name}-$token"] =
        currentPluginBalance?.amount;

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
    if (TokenStakingApi.refresh != null) {
      TokenStakingApi.refresh();
    }
    return datas;
  }

  static clear() {
    TokenStakingApi.balances = {};
  }
}
