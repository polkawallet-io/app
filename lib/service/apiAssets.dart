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

  Future<void> fetchMarketPrices() async {
    final Map res = await WalletApi.getTokenPrices();
    final Map<String, double> prices = {
      'KUSD': 1.0,
      'AUSD': 1.0,
      'USDT': 1.0,
    };
    if (res != null && res['prices'] != null) {
      prices.addAll(Map<String, double>.from(res['prices']));
    }

    apiRoot.store.assets.setMarketPrices(prices);
  }
}
