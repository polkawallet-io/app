import 'package:app/store/types/transferData.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobx/mobx.dart';
import 'package:polkawallet_sdk/api/eth/apiAccountEth.dart';
import 'package:polkawallet_sdk/api/types/evmTxData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';

part 'assets.g.dart';

class AssetsStore extends _AssetsStore with _$AssetsStore {
  AssetsStore(GetStorage storage) : super(storage);
}

abstract class _AssetsStore with Store {
  _AssetsStore(this.storage);

  final GetStorage storage;

  final String cacheTxsKey = 'txs';

  final String customAssetsStoreKey = 'assets_list';

  @observable
  ObservableList<TransferData> txs = ObservableList<TransferData>();

  @observable
  Map<String, Map<String, List<EvmTxData>>> evmTxs = {};

  @observable
  ObservableMap<String, double> marketPrices = ObservableMap<String, double>();

  @observable
  Map<String, bool> customAssets = {};

  @observable
  EvmGasParams gasParams;

  @observable
  ObservableMap<String, EvmTxData> pendingTx = ObservableMap();

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
  void setEvmTxs(List<EvmTxData> data, String token, String address) {
    /// if we got the pending tx from txs api, we remove the local cache.
    if (pendingTx[address] != null && data[0].hash == pendingTx[address].hash) {
      pendingTx.remove(address);
    }

    final allData =
        pendingTx[address] == null ? data : [pendingTx[address], ...data];
    final historyData = evmTxs;
    if (historyData[address] != null) {
      historyData[address][token] = allData;
    } else {
      historyData[address] = {token: allData};
    }
    evmTxs = historyData;
  }

  @action
  void setPendingTx(KeyPairData acc, EvmTxData data) {
    if (data.confirmations != '-1') {
      /// only update pending tx status if we the local cache exists
      if (pendingTx[acc.address] != null &&
          pendingTx[acc.address].hash == data.hash) {
        pendingTx.addAll({acc.address: data});
      }
    } else {
      pendingTx.addAll({acc.address: data});

      /// update evm txs with pending tx data
      final tokenId = data.contractAddress ?? data.tokenSymbol;
      if (evmTxs[acc.address] != null && evmTxs[acc.address][tokenId] != null) {
        setEvmTxs(evmTxs[acc.address][tokenId], tokenId, acc.address);
      }
    }
  }

  @action
  void setMarketPrices(Map<String, double> data) {
    marketPrices.addAll(data);
  }

  @action
  void setCustomAssets(
      KeyPairData acc, String pluginName, Map<String, bool> data) {
    customAssets = data;

    _storeCustomAssets(acc, pluginName, data);
  }

  @action
  void setEvmGasParams(EvmGasParams data) {
    gasParams = data;
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

    final cachedAssetsList =
        await storage.read('${pluginName}_$customAssetsStoreKey');
    if (cachedAssetsList != null && cachedAssetsList[acc.pubKey] != null) {
      customAssets = Map<String, bool>.from(cachedAssetsList[acc.pubKey]);
    } else {
      customAssets = Map<String, bool>();
    }
  }

  @action
  Future<void> loadCache(KeyPairData acc, String pluginName) async {
    loadAccountCache(acc, pluginName);
  }

  Future<void> _storeCustomAssets(
      KeyPairData acc, String pluginName, Map<String, bool> data) async {
    final cachedAssetsList =
        (await storage.read('${pluginName}_$customAssetsStoreKey')) ?? {};

    cachedAssetsList[acc.pubKey] = data;

    storage.write('${pluginName}_$customAssetsStoreKey', cachedAssetsList);
  }
}
