// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$SettingsStore on _SettingsStore, Store {
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

  final _$adBannerStateAtom = Atom(name: '_SettingsStore.adBannerState');

  @override
  Map<dynamic, dynamic> get adBannerState {
    _$adBannerStateAtom.reportRead();
    return super.adBannerState;
  }

  @override
  set adBannerState(Map<dynamic, dynamic> value) {
    _$adBannerStateAtom.reportWrite(value, super.adBannerState, () {
      super.adBannerState = value;
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

  final _$loadNetworkAsyncAction = AsyncAction('_SettingsStore.loadNetwork');

  @override
  Future<void> loadNetwork() {
    return _$loadNetworkAsyncAction.run(() => super.loadNetwork());
  }

  final _$_SettingsStoreActionController =
      ActionController(name: '_SettingsStore');

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
  void setAdBannerState(Map<dynamic, dynamic> value) {
    final _$actionInfo = _$_SettingsStoreActionController.startAction(
        name: '_SettingsStore.setAdBannerState');
    try {
      return super.setAdBannerState(value);
    } finally {
      _$_SettingsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
localeCode: ${localeCode},
network: ${network},
liveModules: ${liveModules},
adBannerState: ${adBannerState}
    ''';
  }
}
