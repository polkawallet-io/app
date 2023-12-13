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

  final _$isDarkThemeAtom = Atom(name: '_SettingsStore.isDarkTheme');

  @override
  bool get isDarkTheme {
    _$isDarkThemeAtom.reportRead();
    return super.isDarkTheme;
  }

  @override
  set isDarkTheme(bool value) {
    _$isDarkThemeAtom.reportWrite(value, super.isDarkTheme, () {
      super.isDarkTheme = value;
    });
  }

  final _$communityMessagesAtom =
      Atom(name: '_SettingsStore.communityMessages');

  @override
  Map<String, List<MessageData>> get communityMessages {
    _$communityMessagesAtom.reportRead();
    return super.communityMessages;
  }

  @override
  set communityMessages(Map<String, List<MessageData>> value) {
    _$communityMessagesAtom.reportWrite(value, super.communityMessages, () {
      super.communityMessages = value;
    });
  }

  final _$systemMessagesAtom = Atom(name: '_SettingsStore.systemMessages');

  @override
  List<MessageData> get systemMessages {
    _$systemMessagesAtom.reportRead();
    return super.systemMessages;
  }

  @override
  set systemMessages(List<MessageData> value) {
    _$systemMessagesAtom.reportWrite(value, super.systemMessages, () {
      super.systemMessages = value;
    });
  }

  final _$communityUnreadNumberAtom =
      Atom(name: '_SettingsStore.communityUnreadNumber');

  @override
  Map<String, int> get communityUnreadNumber {
    _$communityUnreadNumberAtom.reportRead();
    return super.communityUnreadNumber;
  }

  @override
  set communityUnreadNumber(Map<String, int> value) {
    _$communityUnreadNumberAtom.reportWrite(value, super.communityUnreadNumber,
        () {
      super.communityUnreadNumber = value;
    });
  }

  final _$systemUnreadNumberAtom =
      Atom(name: '_SettingsStore.systemUnreadNumber');

  @override
  int get systemUnreadNumber {
    _$systemUnreadNumberAtom.reportRead();
    return super.systemUnreadNumber;
  }

  @override
  set systemUnreadNumber(int value) {
    _$systemUnreadNumberAtom.reportWrite(value, super.systemUnreadNumber, () {
      super.systemUnreadNumber = value;
    });
  }

  final _$dappAllTagsAtom = Atom(name: '_SettingsStore.dappAllTags');

  @override
  List<dynamic> get dappAllTags {
    _$dappAllTagsAtom.reportRead();
    return super.dappAllTags;
  }

  @override
  set dappAllTags(List<dynamic> value) {
    _$dappAllTagsAtom.reportWrite(value, super.dappAllTags, () {
      super.dappAllTags = value;
    });
  }

  final _$dappsAtom = Atom(name: '_SettingsStore.dapps');

  @override
  List<dynamic> get dapps {
    _$dappsAtom.reportRead();
    return super.dapps;
  }

  @override
  set dapps(List<dynamic> value) {
    _$dappsAtom.reportWrite(value, super.dapps, () {
      super.dapps = value;
    });
  }

  final _$websiteAccessAtom = Atom(name: '_SettingsStore.websiteAccess');

  @override
  Map<String, List> get websiteAccess {
    _$websiteAccessAtom.reportRead();
    return super.websiteAccess;
  }

  @override
  set websiteAccess(Map<String, List> value) {
    _$websiteAccessAtom.reportWrite(value, super.websiteAccess, () {
      super.websiteAccess = value;
    });
  }

  final _$websiteAccessEVMAtom = Atom(name: '_SettingsStore.websiteAccessEVM');

  @override
  Map<String, List> get websiteAccessEVM {
    _$websiteAccessEVMAtom.reportRead();
    return super.websiteAccessEVM;
  }

  @override
  set websiteAccessEVM(Map<String, List> value) {
    _$websiteAccessEVMAtom.reportWrite(value, super.websiteAccessEVM, () {
      super.websiteAccessEVM = value;
    });
  }

  final _$_SettingsStoreActionController =
      ActionController(name: '_SettingsStore');

  final _$setTokenStakingConfigAsyncAction =
      AsyncAction('_SettingsStore.setTokenStakingConfig');

  @override
  Future<void> setTokenStakingConfig(Map<dynamic, dynamic> data) {
    return _$setTokenStakingConfigAsyncAction
        .run(() => super.setTokenStakingConfig(data));
  }

  final _$setCommunityMessagesAsyncAction =
      AsyncAction('_SettingsStore.setCommunityMessages');

  @override
  Future<void> setCommunityMessages(Map<String, List<MessageData>> data) {
    return _$setCommunityMessagesAsyncAction
        .run(() => super.setCommunityMessages(data));
  }

  final _$setSystemMessagesAsyncAction =
      AsyncAction('_SettingsStore.setSystemMessages');

  @override
  Future<void> setSystemMessages(List<MessageData> data) {
    return _$setSystemMessagesAsyncAction
        .run(() => super.setSystemMessages(data));
  }

  final _$setCommunityUnreadNumberAsyncAction =
      AsyncAction('_SettingsStore.setCommunityUnreadNumber');

  @override
  Future<void> setCommunityUnreadNumber(Map<String, int> data) {
    return _$setCommunityUnreadNumberAsyncAction
        .run(() => super.setCommunityUnreadNumber(data));
  }

  final _$setSystemUnreadNumberAsyncAction =
      AsyncAction('_SettingsStore.setSystemUnreadNumber');

  @override
  Future<void> setSystemUnreadNumber(int data) {
    return _$setSystemUnreadNumberAsyncAction
        .run(() => super.setSystemUnreadNumber(data));
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
  Future<void> setIsHideBalance(bool hide) {
    return _$setIsHideBalanceAsyncAction
        .run(() => super.setIsHideBalance(hide));
  }

  final _$loadIsHideBalanceAsyncAction =
      AsyncAction('_SettingsStore.loadIsHideBalance');

  @override
  Future<void> loadIsHideBalance() {
    return _$loadIsHideBalanceAsyncAction.run(() => super.loadIsHideBalance());
  }

  @override
  void updateDAppAuth(String url, {List<String> accounts, bool isEvm = false}) {
    final _$actionInfo = _$_SettingsStoreActionController.startAction(
        name: '_AccountStore.updateDAppAuth');
    try {
      return super.updateDAppAuth(url, accounts: accounts, isEvm: isEvm);
    } finally {
      _$_SettingsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void loadDAppAuth() {
    final _$actionInfo = _$_SettingsStoreActionController.startAction(
        name: '_AccountStore.loadDAppAuth');
    try {
      return super.loadDAppAuth();
    } finally {
      _$_SettingsStoreActionController.endAction(_$actionInfo);
    }
  }

  final _$setIsDarkThemeAsyncAction =
      AsyncAction('_SettingsStore.setIsDarkTheme');

  @override
  Future<void> setIsDarkTheme(bool dark) {
    return _$setIsDarkThemeAsyncAction.run(() => super.setIsDarkTheme(dark));
  }

  final _$loadIsDarkThemeAsyncAction =
      AsyncAction('_SettingsStore.loadIsDarkTheme');

  @override
  Future<void> loadIsDarkTheme() {
    return _$loadIsDarkThemeAsyncAction.run(() => super.loadIsDarkTheme());
  }

  @override
  String toString() {
    return '''
localeCode: ${localeCode},
isHideBalance: ${isHideBalance},
isDarkTheme: ${isDarkTheme},
communityMessages: ${communityMessages},
systemMessages: ${systemMessages},
communityUnreadNumber: ${communityUnreadNumber},
systemUnreadNumber: ${systemUnreadNumber},
dappAllTags: ${dappAllTags},
dapps: ${dapps}
    ''';
  }
}
