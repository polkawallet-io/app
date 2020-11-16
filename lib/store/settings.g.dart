// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$SettingsStore on _SettingsStore, Store {
  final _$loadingAtom = Atom(name: '_SettingsStore.loading');

  @override
  bool get loading {
    _$loadingAtom.reportRead();
    return super.loading;
  }

  @override
  set loading(bool value) {
    _$loadingAtom.reportWrite(value, super.loading, () {
      super.loading = value;
    });
  }

  final _$localeCodeAtom = Atom(name: '_SettingsStore.localeCode');

  @override
  String get localeCode {
    _$localeCodeAtom.reportRead();
    return super.localeCode;
  }

  @override
  set localeCode(String value) {
    _$localeCodeAtom.reportWrite(value, super.localeCode, () {
      super.localeCode = value;
    });
  }

  final _$networkAtom = Atom(name: '_SettingsStore.network');

  @override
  String get network {
    _$networkAtom.reportRead();
    return super.network;
  }

  @override
  set network(String value) {
    _$networkAtom.reportWrite(value, super.network, () {
      super.network = value;
    });
  }

  final _$customSS58FormatAtom = Atom(name: '_SettingsStore.customSS58Format');

  @override
  Map<String, dynamic> get customSS58Format {
    _$customSS58FormatAtom.reportRead();
    return super.customSS58Format;
  }

  @override
  set customSS58Format(Map<String, dynamic> value) {
    _$customSS58FormatAtom.reportWrite(value, super.customSS58Format, () {
      super.customSS58Format = value;
    });
  }

  final _$networkNameAtom = Atom(name: '_SettingsStore.networkName');

  @override
  String get networkName {
    _$networkNameAtom.reportRead();
    return super.networkName;
  }

  @override
  set networkName(String value) {
    _$networkNameAtom.reportWrite(value, super.networkName, () {
      super.networkName = value;
    });
  }

  final _$networkStateAtom = Atom(name: '_SettingsStore.networkState');

  @override
  NetworkStateData get networkState {
    _$networkStateAtom.reportRead();
    return super.networkState;
  }

  @override
  set networkState(NetworkStateData value) {
    _$networkStateAtom.reportWrite(value, super.networkState, () {
      super.networkState = value;
    });
  }

  final _$networkConstAtom = Atom(name: '_SettingsStore.networkConst');

  @override
  Map<dynamic, dynamic> get networkConst {
    _$networkConstAtom.reportRead();
    return super.networkConst;
  }

  @override
  set networkConst(Map<dynamic, dynamic> value) {
    _$networkConstAtom.reportWrite(value, super.networkConst, () {
      super.networkConst = value;
    });
  }

  final _$liveModulesAtom = Atom(name: '_SettingsStore.liveModules');

  @override
  Map<dynamic, dynamic> get liveModules {
    _$liveModulesAtom.reportRead();
    return super.liveModules;
  }

  @override
  set liveModules(Map<dynamic, dynamic> value) {
    _$liveModulesAtom.reportWrite(value, super.liveModules, () {
      super.liveModules = value;
    });
  }

  final _$initAsyncAction = AsyncAction('_SettingsStore.init');

  @override
  Future<void> init() {
    return _$initAsyncAction.run(() => super.init());
  }

  final _$setLocalCodeAsyncAction = AsyncAction('_SettingsStore.setLocalCode');

  @override
  Future<void> setLocalCode(String code) {
    return _$setLocalCodeAsyncAction.run(() => super.setLocalCode(code));
  }

  final _$loadLocalCodeAsyncAction =
      AsyncAction('_SettingsStore.loadLocalCode');

  @override
  Future<void> loadLocalCode() {
    return _$loadLocalCodeAsyncAction.run(() => super.loadLocalCode());
  }

  final _$setNetworkStateAsyncAction =
      AsyncAction('_SettingsStore.setNetworkState');

  @override
  Future<void> setNetworkState(Map<String, dynamic> data,
      {bool needCache = true}) {
    return _$setNetworkStateAsyncAction
        .run(() => super.setNetworkState(data, needCache: needCache));
  }

  final _$loadNetworkStateCacheAsyncAction =
      AsyncAction('_SettingsStore.loadNetworkStateCache');

  @override
  Future<void> loadNetworkStateCache() {
    return _$loadNetworkStateCacheAsyncAction
        .run(() => super.loadNetworkStateCache());
  }

  final _$setNetworkConstAsyncAction =
      AsyncAction('_SettingsStore.setNetworkConst');

  @override
  Future<void> setNetworkConst(Map<String, dynamic> data,
      {bool needCache = true}) {
    return _$setNetworkConstAsyncAction
        .run(() => super.setNetworkConst(data, needCache: needCache));
  }

  final _$loadNetworkAsyncAction = AsyncAction('_SettingsStore.loadNetwork');

  @override
  Future<void> loadNetwork() {
    return _$loadNetworkAsyncAction.run(() => super.loadNetwork());
  }

  final _$loadCustomSS58FormatAsyncAction =
      AsyncAction('_SettingsStore.loadCustomSS58Format');

  @override
  Future<void> loadCustomSS58Format() {
    return _$loadCustomSS58FormatAsyncAction
        .run(() => super.loadCustomSS58Format());
  }

  final _$_SettingsStoreActionController =
      ActionController(name: '_SettingsStore');

  @override
  void setNetworkLoading(bool isLoading) {
    final _$actionInfo = _$_SettingsStoreActionController.startAction(
        name: '_SettingsStore.setNetworkLoading');
    try {
      return super.setNetworkLoading(isLoading);
    } finally {
      _$_SettingsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setNetworkName(String name) {
    final _$actionInfo = _$_SettingsStoreActionController.startAction(
        name: '_SettingsStore.setNetworkName');
    try {
      return super.setNetworkName(name);
    } finally {
      _$_SettingsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setNetwork(String value) {
    final _$actionInfo = _$_SettingsStoreActionController.startAction(
        name: '_SettingsStore.setNetwork');
    try {
      return super.setNetwork(value);
    } finally {
      _$_SettingsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCustomSS58Format(Map<String, dynamic> value) {
    final _$actionInfo = _$_SettingsStoreActionController.startAction(
        name: '_SettingsStore.setCustomSS58Format');
    try {
      return super.setCustomSS58Format(value);
    } finally {
      _$_SettingsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setLiveModules(Map<dynamic, dynamic> value) {
    final _$actionInfo = _$_SettingsStoreActionController.startAction(
        name: '_SettingsStore.setLiveModules');
    try {
      return super.setLiveModules(value);
    } finally {
      _$_SettingsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
loading: ${loading},
localeCode: ${localeCode},
network: ${network},
customSS58Format: ${customSS58Format},
networkName: ${networkName},
networkState: ${networkState},
networkConst: ${networkConst},
liveModules: ${liveModules}
    ''';
  }
}
