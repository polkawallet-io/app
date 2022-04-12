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
  String toString() {
    return '''
localeCode: ${localeCode},
isHideBalance: ${isHideBalance},
communityMessages: ${communityMessages},
systemMessages: ${systemMessages},
communityUnreadNumber: ${communityUnreadNumber},
systemUnreadNumber: ${systemUnreadNumber}
    ''';
  }
}
