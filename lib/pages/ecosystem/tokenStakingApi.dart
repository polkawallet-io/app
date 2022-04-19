import 'dart:convert';

import 'package:app/service/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';

class TokenStakingApi {
  static Future<Map<String, TokenBalanceData>> getBalance(
      AppService service, List<String> networkNames, String token) async {
    final connected = await service.plugin.sdk.webView
        .evalJavascript('xcm.connectFromChain(${json.encode(networkNames)})');
    if (connected != null) {
      Map<String, TokenBalanceData> balances = Map<String, TokenBalanceData>();
      var cacheTokenStakingAssets = service.assets
              .getTokenStakingAssets(service.keyring.current.pubKey) ??
          Map<String, dynamic>();
      for (int i = 0; i < networkNames.length; i++) {
        final element = networkNames[i];
        final data = await service.plugin.sdk.webView.evalJavascript(
            'xcm.getBalances("$element", "${service.keyring.current.address}", ["$token"])');
        if (data != null) {
          final balance = List.of(data)[0];
          if (balance != null) {
            final balanceData = TokenBalanceData(
                tokenNameId: balance['tokenNameId'],
                amount: balance['amount'],
                decimals: balance['decimals'],
                symbol: token,
                name: token,
                currencyId: {'Token': token},
                isCacheChange: cacheTokenStakingAssets == null ||
                        cacheTokenStakingAssets["$element-$token"] == null
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
      service.assets.setTokenStakingAssets(
          service.keyring.current.pubKey, cacheTokenStakingAssets);
      return balances;
    }
    return null;
  }
}
