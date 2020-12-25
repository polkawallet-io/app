import 'package:app/service/index.dart';

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

    final Map res =
        await apiRoot.subScan.fetchTokenPriceAsync(apiRoot.plugin.basic.name);
    if (res['token'] == null) {
      print('fetch market price failed');
      return;
    }
    final String token = res['token'][0];
    apiRoot.store.assets.setMarketPrices(token, res['detail'][token]['price']);
  }
}
