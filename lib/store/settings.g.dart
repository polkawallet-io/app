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

  final _$isHideBalanceAtom = Atom(name: '_SettingsStore.isHideBalance');

  @override
  bool get isHideBalance {
    _$isHideBalanceAtom.reportRead();
    return super.isHideBalance;
  }

  @override
  set isHideBalance(bool value) {
    _$isHideBalanceAtom.reportWrite(value, super.isHideBalance, () {
      super.isHideBalance = value;
    });
  }

  String get network {
    return super.network;
  }

  set network(String value) {
    super.network = value;
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

  Map<dynamic, dynamic> get adBannerState {
    return super.adBannerState;
  }

  set adBannerState(Map<dynamic, dynamic> value) {
    super.adBannerState = value;
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

  final _$setIsHideBalanceAsyncAction =
      AsyncAction('_SettingsStore.setIsHideBalance');

  @override
  Future<void> setIsHideBalance(bool code) {
    return _$setIsHideBalanceAsyncAction
        .run(() => super.setIsHideBalance(code));
  }

  final _$loadIsHideBalanceAsyncAction =
      AsyncAction('_SettingsStore.loadIsHideBalance');

  @override
  Future<void> loadIsHideBalance() {
    return _$loadIsHideBalanceAsyncAction.run(() => super.loadIsHideBalance());
  }

  Future<void> loadNetwork() {
    return super.loadNetwork();
  }

  final _$_SettingsStoreActionController =
      ActionController(name: '_SettingsStore');

  void setNetwork(String value) {
    return super.setNetwork(value);
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

  void setAdBannerState(Map<dynamic, dynamic> value) {
    return super.setAdBannerState(value);
  }

  @override
  String toString() {
    return '''
localeCode: ${localeCode},
network: ${network},
priceCurrency: ${priceCurrency},
isHideBalance: ${isHideBalance},
liveModules: ${liveModules},
adBannerState: ${adBannerState}
    ''';
  }
}
