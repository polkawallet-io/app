// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assets.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$AssetsStore on _AssetsStore, Store {
  final _$txsAtom = Atom(name: '_AssetsStore.txs');

  @override
  ObservableList<TransferData> get txs {
    _$txsAtom.reportRead();
    return super.txs;
  }

  @override
  set txs(ObservableList<TransferData> value) {
    _$txsAtom.reportWrite(value, super.txs, () {
      super.txs = value;
    });
  }

  final _$marketPricesAtom = Atom(name: '_AssetsStore.marketPrices');

  @override
  ObservableMap<String, double> get marketPrices {
    _$marketPricesAtom.reportRead();
    return super.marketPrices;
  }

  @override
  set marketPrices(ObservableMap<String, double> value) {
    _$marketPricesAtom.reportWrite(value, super.marketPrices, () {
      super.marketPrices = value;
    });
  }

  final _$customAssetsAtom = Atom(name: '_AssetsStore.customAssets');

  @override
  Map<String, bool> get customAssets {
    _$customAssetsAtom.reportRead();
    return super.customAssets;
  }

  @override
  set customAssets(Map<String, bool> value) {
    _$customAssetsAtom.reportWrite(value, super.customAssets, () {
      super.customAssets = value;
    });
  }

  final _$clearTxsAsyncAction = AsyncAction('_AssetsStore.clearTxs');

  @override
  Future<void> clearTxs() {
    return _$clearTxsAsyncAction.run(() => super.clearTxs());
  }

  final _$addTxsAsyncAction = AsyncAction('_AssetsStore.addTxs');

  @override
  Future<void> addTxs(
      Map<dynamic, dynamic> res, KeyPairData acc, String pluginName,
      {bool shouldCache = false}) {
    return _$addTxsAsyncAction.run(
        () => super.addTxs(res, acc, pluginName, shouldCache: shouldCache));
  }

  final _$loadAccountCacheAsyncAction =
      AsyncAction('_AssetsStore.loadAccountCache');

  @override
  Future<void> loadAccountCache(KeyPairData acc, String pluginName) {
    return _$loadAccountCacheAsyncAction
        .run(() => super.loadAccountCache(acc, pluginName));
  }

  final _$loadCacheAsyncAction = AsyncAction('_AssetsStore.loadCache');

  @override
  Future<void> loadCache(KeyPairData acc, String pluginName) {
    return _$loadCacheAsyncAction.run(() => super.loadCache(acc, pluginName));
  }

  final _$_AssetsStoreActionController = ActionController(name: '_AssetsStore');

  @override
  void setMarketPrices(Map<String, double> data) {
    final _$actionInfo = _$_AssetsStoreActionController.startAction(
        name: '_AssetsStore.setMarketPrices');
    try {
      return super.setMarketPrices(data);
    } finally {
      _$_AssetsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCustomAssets(
      KeyPairData acc, String pluginName, Map<String, bool> data) {
    final _$actionInfo = _$_AssetsStoreActionController.startAction(
        name: '_AssetsStore.setCustomAssets');
    try {
      return super.setCustomAssets(acc, pluginName, data);
    } finally {
      _$_AssetsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
txs: ${txs},
marketPrices: ${marketPrices},
customAssets: ${customAssets}
    ''';
  }
}
