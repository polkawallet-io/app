// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$AccountStore on _AccountStore, Store {
  final _$newAccountAtom = Atom(name: '_AccountStore.newAccount');

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

  final _$accountCreatedAtom = Atom(name: '_AccountStore.accountCreated');

  @override
  bool get accountCreated {
    _$accountCreatedAtom.reportRead();
    return super.accountCreated;
  }

  @override
  set accountCreated(bool value) {
    _$accountCreatedAtom.reportWrite(value, super.accountCreated, () {
      super.accountCreated = value;
    });
  }

  final _$pubKeyAddressMapAtom = Atom(name: '_AccountStore.pubKeyAddressMap');

  @override
  ObservableMap<int, Map<String, String>> get pubKeyAddressMap {
    _$pubKeyAddressMapAtom.reportRead();
    return super.pubKeyAddressMap;
  }

  @override
  set pubKeyAddressMap(ObservableMap<int, Map<String, String>> value) {
    _$pubKeyAddressMapAtom.reportWrite(value, super.pubKeyAddressMap, () {
      super.pubKeyAddressMap = value;
    });
  }

  final _$addressIconsMapAtom = Atom(name: '_AccountStore.addressIconsMap');

  @override
  ObservableMap<String, String> get addressIconsMap {
    _$addressIconsMapAtom.reportRead();
    return super.addressIconsMap;
  }

  @override
  set addressIconsMap(ObservableMap<String, String> value) {
    _$addressIconsMapAtom.reportWrite(value, super.addressIconsMap, () {
      super.addressIconsMap = value;
    });
  }

  final _$recoveryInfoAtom = Atom(name: '_AccountStore.recoveryInfo');

  @override
  RecoveryInfo get recoveryInfo {
    _$recoveryInfoAtom.reportRead();
    return super.recoveryInfo;
  }

  @override
  set recoveryInfo(RecoveryInfo value) {
    _$recoveryInfoAtom.reportWrite(value, super.recoveryInfo, () {
      super.recoveryInfo = value;
    });
  }

  final _$walletConnectPairingAtom =
      Atom(name: '_AccountStore.walletConnectPairing');

  @override
  bool get walletConnectPairing {
    _$walletConnectPairingAtom.reportRead();
    return super.walletConnectPairing;
  }

  @override
  set walletConnectPairing(bool value) {
    _$walletConnectPairingAtom.reportWrite(value, super.walletConnectPairing,
        () {
      super.walletConnectPairing = value;
    });
  }

  final _$wcSessionURIAtom = Atom(name: '_AccountStore.wcSessionURI');

  @override
  String get wcSessionURI {
    _$wcSessionURIAtom.reportRead();
    return super.wcSessionURI;
  }

  @override
  set wcSessionURI(String value) {
    _$wcSessionURIAtom.reportWrite(value, super.wcSessionURI, () {
      super.wcSessionURI = value;
    });
  }

  final _$wcSessionAtom = Atom(name: '_AccountStore.wcSession');

  @override
  WCProposerMeta get wcSession {
    _$wcSessionAtom.reportRead();
    return super.wcSession;
  }

  @override
  set wcSession(WCProposerMeta value) {
    _$wcSessionAtom.reportWrite(value, super.wcSession, () {
      super.wcSession = value;
    });
  }

  final _$wcCallRequestsAtom = Atom(name: '_AccountStore.wcCallRequests');

  @override
  ObservableList<WCCallRequestData> get wcCallRequests {
    _$wcCallRequestsAtom.reportRead();
    return super.wcCallRequests;
  }

  @override
  set wcCallRequests(ObservableList<WCCallRequestData> value) {
    _$wcCallRequestsAtom.reportWrite(value, super.wcCallRequests, () {
      super.wcCallRequests = value;
    });
  }

  final _$wcV2SessionsAtom = Atom(name: '_AccountStore.wcV2Sessions');

  @override
  ObservableList<WCSessionDataV2> get wcV2Sessions {
    _$wcV2SessionsAtom.reportRead();
    return super.wcV2Sessions;
  }

  @override
  set wcV2Sessions(ObservableList<WCSessionDataV2> value) {
    _$wcV2SessionsAtom.reportWrite(value, super.wcV2Sessions, () {
      super.wcV2Sessions = value;
    });
  }

  final _$accountTypeAtom = Atom(name: '_AccountStore.accountType');

  @override
  AccountType get accountType {
    _$accountTypeAtom.reportRead();
    return super.accountType;
  }

  @override
  set accountType(AccountType value) {
    _$accountTypeAtom.reportWrite(value, super.accountType, () {
      super.accountType = value;
    });
  }

  final _$initAsyncAction = AsyncAction('_AccountStore.init');
  @override
  Future<void> init() {
    return _$initAsyncAction.run(() => super.init());
  }

  final _$_AccountStoreActionController =
      ActionController(name: '_AccountStore');

  @override
  void setNewAccount(String name, String password) {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.setNewAccount');
    try {
      return super.setNewAccount(name, password);
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setNewAccountKey(String key) {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.setNewAccountKey');
    try {
      return super.setNewAccountKey(key);
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetNewAccount() {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.resetNewAccount');
    try {
      return super.resetNewAccount();
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAccountCreated(bool created) {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.setAccountCreated');
    try {
      return super.setAccountCreated(created);
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPubKeyAddressMap(Map<String, Map<dynamic, dynamic>> data) {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.setPubKeyAddressMap');
    try {
      return super.setPubKeyAddressMap(data);
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAddressIconsMap(List<dynamic> list) {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.setAddressIconsMap');
    try {
      return super.setAddressIconsMap(list);
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAccountRecoveryInfo(RecoveryInfo data) {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.setAccountRecoveryInfo');
    try {
      return super.setAccountRecoveryInfo(data);
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setWCPairing(bool pairing) {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.setWCPairing');
    try {
      return super.setWCPairing(pairing);
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setWCSession(String uri, WCProposerMeta peerMeta, Map session) {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.setWCSession');
    try {
      return super.setWCSession(uri, peerMeta, session);
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addWCSessionV2(Map session) {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.addWCSessionV2');
    try {
      return super.addWCSessionV2(session);
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteWCSessionV2(String topic) {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.deleteWCSessionV2');
    try {
      return super.deleteWCSessionV2(topic);
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addCallRequest(WCCallRequestData data) {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.addCallRequest');
    try {
      return super.addCallRequest(data);
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void closeCallRequest(int id) {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.closeCallRequest');
    try {
      return super.closeCallRequest(id);
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearCallRequests() {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.clearCallRequests');
    try {
      return super.clearCallRequests();
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAccountType(AccountType type) {
    final _$actionInfo = _$_AccountStoreActionController.startAction(
        name: '_AccountStore.setAccountType');
    try {
      return super.setAccountType(type);
    } finally {
      _$_AccountStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
newAccount: ${newAccount},
accountCreated: ${accountCreated},
pubKeyAddressMap: ${pubKeyAddressMap},
addressIconsMap: ${addressIconsMap},
recoveryInfo: ${recoveryInfo},
walletConnectPairing: ${walletConnectPairing},
wcSessionURI: ${wcSessionURI},
wcSession: ${wcSession.toJson()},
accountType: ${accountType}
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
