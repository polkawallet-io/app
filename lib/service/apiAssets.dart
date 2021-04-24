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

  Future<void> fetchMarketPrice() async {
    if (apiRoot.plugin.basic.isTestNet) return;

    final res = await WalletApi.getTokenPrice(apiRoot.plugin.basic.name);
    if (res == null || res['data'] == null) {
      print('fetch market price failed');
      return;
    }
    final symbol = res['data']['token'][0];
    apiRoot.store.assets
        .setMarketPrices(symbol, res['data']['detail'][symbol]['price']);
  }
}
