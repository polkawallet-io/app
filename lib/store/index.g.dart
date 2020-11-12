// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$AppStore on _AppStore, Store {
  final _$loadingAtom = Atom(name: '_AppStore.loading');

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

  final _$localeCodeAtom = Atom(name: '_AppStore.localeCode');

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

  final _$networkAtom = Atom(name: '_AppStore.network');

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

  final _$customSS58FormatAtom = Atom(name: '_AppStore.customSS58Format');

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

  final _$networkNameAtom = Atom(name: '_AppStore.networkName');

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

  final _$networkStateAtom = Atom(name: '_AppStore.networkState');

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

  final _$networkConstAtom = Atom(name: '_AppStore.networkConst');

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

  final _$newAccountAtom = Atom(name: '_AppStore.newAccount');

  @override
  AccountCreate get newAccount {
    _$newAccountAtom.reportRead();
    return super.newAccount;
  }

  @override
  set newAccount(AccountCreate value) {
    _$newAccountAtom.reportWrite(value, super.newAccount, () {
      super.newAccount = value;
    });
  }

  final _$liveModulesAtom = Atom(name: '_AppStore.liveModules');

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

  final _$initAsyncAction = AsyncAction('_AppStore.init');

  @override
  Future<void> init(String sysLocaleCode) {
    return _$initAsyncAction.run(() => super.init(sysLocaleCode));
  }

  final _$setLocalCodeAsyncAction = AsyncAction('_AppStore.setLocalCode');

  @override
  Future<void> setLocalCode(String code) {
    return _$setLocalCodeAsyncAction.run(() => super.setLocalCode(code));
  }

  final _$loadLocalCodeAsyncAction = AsyncAction('_AppStore.loadLocalCode');

  @override
  Future<void> loadLocalCode() {
    return _$loadLocalCodeAsyncAction.run(() => super.loadLocalCode());
  }

  final _$setNetworkStateAsyncAction = AsyncAction('_AppStore.setNetworkState');

  @override
  Future<void> setNetworkState(Map<String, dynamic> data,
      {bool needCache = true}) {
    return _$setNetworkStateAsyncAction
        .run(() => super.setNetworkState(data, needCache: needCache));
  }

  final _$loadNetworkStateCacheAsyncAction =
      AsyncAction('_AppStore.loadNetworkStateCache');

  @override
  Future<void> loadNetworkStateCache() {
    return _$loadNetworkStateCacheAsyncAction
        .run(() => super.loadNetworkStateCache());
  }

  final _$setNetworkConstAsyncAction = AsyncAction('_AppStore.setNetworkConst');

  @override
  Future<void> setNetworkConst(Map<String, dynamic> data,
      {bool needCache = true}) {
    return _$setNetworkConstAsyncAction
        .run(() => super.setNetworkConst(data, needCache: needCache));
  }

  final _$loadNetworkAsyncAction = AsyncAction('_AppStore.loadNetwork');

  @override
  Future<void> loadNetwork() {
    return _$loadNetworkAsyncAction.run(() => super.loadNetwork());
  }

  final _$loadCustomSS58FormatAsyncAction =
      AsyncAction('_AppStore.loadCustomSS58Format');

  @override
  Future<void> loadCustomSS58Format() {
    return _$loadCustomSS58FormatAsyncAction
        .run(() => super.loadCustomSS58Format());
  }

  final _$_AppStoreActionController = ActionController(name: '_AppStore');

  @override
  void setNetworkLoading(bool isLoading) {
    final _$actionInfo = _$_AppStoreActionController.startAction(
        name: '_AppStore.setNetworkLoading');
    try {
      return super.setNetworkLoading(isLoading);
    } finally {
      _$_AppStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setNetworkName(String name) {
    final _$actionInfo = _$_AppStoreActionController.startAction(
        name: '_AppStore.setNetworkName');
    try {
      return super.setNetworkName(name);
    } finally {
      _$_AppStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setNetwork(String value) {
    final _$actionInfo =
        _$_AppStoreActionController.startAction(name: '_AppStore.setNetwork');
    try {
      return super.setNetwork(value);
    } finally {
      _$_AppStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCustomSS58Format(Map<String, dynamic> value) {
    final _$actionInfo = _$_AppStoreActionController.startAction(
        name: '_AppStore.setCustomSS58Format');
    try {
      return super.setCustomSS58Format(value);
    } finally {
      _$_AppStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setNewAccount(String name, String password) {
    final _$actionInfo = _$_AppStoreActionController.startAction(
        name: '_AppStore.setNewAccount');
    try {
      return super.setNewAccount(name, password);
    } finally {
      _$_AppStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setNewAccountKey(String key) {
    final _$actionInfo = _$_AppStoreActionController.startAction(
        name: '_AppStore.setNewAccountKey');
    try {
      return super.setNewAccountKey(key);
    } finally {
      _$_AppStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetNewAccount() {
    final _$actionInfo = _$_AppStoreActionController.startAction(
        name: '_AppStore.resetNewAccount');
    try {
      return super.resetNewAccount();
    } finally {
      _$_AppStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setLiveModules(Map<dynamic, dynamic> value) {
    final _$actionInfo = _$_AppStoreActionController.startAction(
        name: '_AppStore.setLiveModules');
    try {
      return super.setLiveModules(value);
    } finally {
      _$_AppStoreActionController.endAction(_$actionInfo);
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
newAccount: ${newAccount},
liveModules: ${liveModules}
    ''';
  }
}

mixin _$AccountCreate on _AccountCreate, Store {
  final _$nameAtom = Atom(name: '_AccountCreate.name');

  @override
  String get name {
    _$nameAtom.reportRead();
    return super.name;
  }

  @override
  set name(String value) {
    _$nameAtom.reportWrite(value, super.name, () {
      super.name = value;
    });
  }

  final _$passwordAtom = Atom(name: '_AccountCreate.password');

  @override
  String get password {
    _$passwordAtom.reportRead();
    return super.password;
  }

  @override
  set password(String value) {
    _$passwordAtom.reportWrite(value, super.password, () {
      super.password = value;
    });
  }

  final _$keyAtom = Atom(name: '_AccountCreate.key');

  @override
  String get key {
    _$keyAtom.reportRead();
    return super.key;
  }

  @override
  set key(String value) {
    _$keyAtom.reportWrite(value, super.key, () {
      super.key = value;
    });
  }

  @override
  String toString() {
    return '''
name: ${name},
password: ${password},
key: ${key}
    ''';
  }
}
