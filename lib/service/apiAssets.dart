import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';

class ApiAssets {
  ApiAssets(this.apiRoot);

  final AppService apiRoot;

  Future<Map> updateTxs(int page) async {
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

    return res;
  }

  Future<void> fetchMarketPrices(List<String> tokens) async {
    final List res = await Future.wait(
        tokens.map((e) => WalletApi.getTokenPrice(e)).toList());
    final Map<String, double> prices = {
      'KUSD': 1.0,
      'AUSD': 1.0,
    };
    res.asMap().forEach((k, e) {
      if (e != null && e['code'] == 1) {
        prices[tokens[k]] =
            double.tryParse(e['data']['price'][0].toString()) ?? 0;
      }
    });
    apiRoot.store.assets.setMarketPrices(prices);
  }
}
