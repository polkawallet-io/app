import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';

class ApiAssets {
  ApiAssets(this.apiRoot);

  final AppService apiRoot;

  Future<Map> updateTxs(int page) async {
    apiRoot.store.assets.setTxsLoading(true);

    final acc = apiRoot.keyring.current;
    Map res = await apiRoot.subScan.fetchTransfersAsync(
      acc.address,
      page,
      network: apiRoot.plugin.basic.name,
    );

    if (page == 0) {
      apiRoot.store.assets.clearTxs();
    }
    // cache first page of txs
    await apiRoot.store.assets.addTxs(
      res,
      acc,
      apiRoot.plugin.basic.name,
      shouldCache: page == 0,
    );

    apiRoot.store.assets.setTxsLoading(false);
    return res;
  }

  Future<void> fetchMarketPriceFromSubScan() async {
    if (apiRoot.plugin.basic.isTestNet) return;

    final res =
        await WalletApi.getTokenPriceFromSubScan(apiRoot.plugin.basic.name);
    if (res == null || res['data'] == null) {
      print('fetch market price failed');
      return;
    }
    final symbol = res['data']['token'][0];
    apiRoot.store.assets.setMarketPrices(
        {symbol: double.parse(res['data']['detail'][symbol]['price'])});
  }

  Future<void> fetchMarketPrices(List<String> tokens) async {
    final List res = await Future.wait(
        tokens.map((e) => WalletApi.getTokenPrice(e)).toList());

    final Map<String, double> prices = {
      'KUSD': 1.0,
      'AUSD': 1.0,
    };
    res.forEach((e) {
      if (e != null && e['price'] != null) {
        prices[e['token']] = double.parse(e['price']);
      }
    });
    apiRoot.store.assets.setMarketPrices(prices);
  }

  Future<void> updateBalances() async {
    final balances = await apiRoot.plugin.sdk.api.account
        .queryBalance(apiRoot.keyring.current.address);
    apiRoot.plugin.updateBalances(apiRoot.keyring.current, balances);
  }
}
