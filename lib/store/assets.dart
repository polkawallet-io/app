import 'package:app/store/types/transferData.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobx/mobx.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';

part 'assets.g.dart';

class AssetsStore extends _AssetsStore with _$AssetsStore {
  AssetsStore(GetStorage storage) : super(storage);
}

abstract class _AssetsStore with Store {
  _AssetsStore(this.storage);

  final GetStorage storage;

  final String cacheTxsKey = 'txs';

  @observable
  int cacheTxsTimestamp = 0;

  @observable
  bool isTxsLoading = true;

  @observable
  bool submitting = false;

  @observable
  int txsCount = 0;

  @observable
  ObservableList<TransferData> txs = ObservableList<TransferData>();

  @observable
  ObservableMap<String, double> marketPrices = ObservableMap<String, double>();

  @action
  void setTxsLoading(bool isLoading) {
    isTxsLoading = isLoading;
  }

  @action
  Future<void> clearTxs() async {
    txs.clear();
  }

  @action
  Future<void> addTxs(
    Map res,
    KeyPairData acc,
    String pluginName, {
    bool shouldCache = false,
  }) async {
    txsCount = res['count'];

    List ls = res['transfers'];
    if (ls == null) return;

    ls.forEach((i) {
      TransferData tx = TransferData.fromJson(i);
      txs.add(tx);
    });

    if (shouldCache) {
      storage.write('${pluginName}_$acc', ls);
    }
  }

  @action
  void setSubmitting(bool isSubmitting) {
    submitting = isSubmitting;
  }

  @action
  void setMarketPrices(String token, String price) {
    marketPrices[token] = double.parse(price);
  }

  @action
  Future<void> loadAccountCache(KeyPairData acc, String pluginName) async {
    // return if currentAccount not exist
    if (acc == null) {
      return;
    }

    final List cache = await storage.read('${pluginName}_$cacheTxsKey');
    if (cache != null) {
      txs = ObservableList.of(
          cache.map((i) => TransferData.fromJson(i)).toList());
    } else {
      txs = ObservableList();
    }
  }

  @action
  Future<void> loadCache(KeyPairData acc, String pluginName) async {
    loadAccountCache(acc, pluginName);
  }
}
