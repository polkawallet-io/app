import 'dart:async';
import 'dart:convert';

import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/utils/Utils.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobx/mobx.dart';
import 'package:polkawallet_sdk/api/types/recoveryInfo.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';

part 'account.g.dart';

class AccountStore extends _AccountStore with _$AccountStore {
  AccountStore(this.storage) : super(storage);

  final GetStorage storage;
}

abstract class _AccountStore with Store {
  _AccountStore(this.storage);
  final GetStorage storage;

  final String localStorageAccountTypeKey = 'accountType';
  final String localStorageWCSessionURIKey = 'wcSessionURI';
  final String localStorageWCSessionKey = 'wcSession';
  final String localStorageWCSessionV2Key = 'wcV2Session';

  @observable
  AccountCreate newAccount = AccountCreate();

  @observable
  bool accountCreated = false;

  @observable
  ObservableMap<int, Map<String, String>> pubKeyAddressMap =
      ObservableMap<int, Map<String, String>>();

  @observable
  ObservableMap<String, String> addressIconsMap =
      ObservableMap<String, String>();

  @observable
  RecoveryInfo recoveryInfo = RecoveryInfo();

  @observable
  bool walletConnectPairing = false;

  @observable
  String wcSessionURI;

  @observable
  WCProposerMeta wcSession;

  @observable
  ObservableList<WCCallRequestData> wcCallRequests =
      ObservableList<WCCallRequestData>();

  @observable
  ObservableList<WCSessionDataV2> wcV2Sessions =
      ObservableList<WCSessionDataV2>();

  @observable
  AccountType accountType = AccountType.Substrate;

  @action
  void setNewAccount(String name, String password) {
    newAccount.name = name;
    newAccount.password = password;
  }

  @action
  void setNewAccountKey(String key) {
    newAccount.key = key;
  }

  @action
  void resetNewAccount() {
    newAccount = AccountCreate();
  }

  @action
  void setAccountCreated(bool created) {
    accountCreated = created;
  }

  @action
  void setPubKeyAddressMap(Map<String, Map> data) {
    data.keys.forEach((ss58) {
      // get old data map
      Map<String, String> addresses =
          Map.of(pubKeyAddressMap[int.parse(ss58)] ?? {});
      // set new data
      Map.of(data[ss58]).forEach((k, v) {
        addresses[k] = v;
      });
      // update state
      pubKeyAddressMap[int.parse(ss58)] = addresses;
    });
  }

  @action
  void setAddressIconsMap(List list) {
    list.forEach((i) {
      addressIconsMap[i[0]] = i[1];
    });
  }

  @action
  void setAccountRecoveryInfo(RecoveryInfo data) {
    recoveryInfo = data ?? RecoveryInfo();
  }

  @action
  void setWCPairing(bool pairing) {
    walletConnectPairing = pairing;
  }

  @action
  void setWCSession(String uri, WCProposerMeta peerMeta, Map session) {
    wcSessionURI = uri;
    wcSession = peerMeta;

    storage.write(localStorageWCSessionURIKey, wcSessionURI);
    storage.write(localStorageWCSessionKey, session);

    if (uri == null) {
      clearCallRequests();
    }
  }

  @action
  void addWCSessionV2(Map session) {
    if (wcV2Sessions.indexWhere((e) => e.topic == session['topic']) == -1) {
      wcV2Sessions.add(WCSessionDataV2.fromJson(session));

      storage.write(localStorageWCSessionV2Key, session['storage']);
    }
  }

  @action
  void deleteWCSessionV2(String topic) {
    wcV2Sessions.removeWhere((e) => e.topic == topic);

    Utils.deleteWC2SessionInStorage(storage, localStorageWCSessionV2Key, topic);

    wcCallRequests.removeWhere((e) => e.topic == topic);
  }

  @action
  void addCallRequest(WCCallRequestData data) {
    wcCallRequests.add(data);
  }

  @action
  void closeCallRequest(int id) {
    wcCallRequests.removeWhere((e) => e.id == id);
  }

  @action
  void clearCallRequests() {
    wcCallRequests.clear();
  }

  @action
  void setAccountType(AccountType type) {
    accountType = type;
    storage.write(localStorageAccountTypeKey, accountType.name.toString());
  }

  @action
  Future<void> init() async {
    final accType = storage.read(localStorageAccountTypeKey);
    if (accType != null) {
      accountType =
          AccountType.values.firstWhere((e) => e.toString().contains(accType));
    }

    final String cachedURI = storage.read(localStorageWCSessionURIKey);
    if (cachedURI != null) {
      wcSessionURI = cachedURI;

      final session = storage.read(localStorageWCSessionKey);
      if (session != null) {
        wcSession = WCProposerMeta.fromJson(session['peerMeta']);
      }
    }

    final sessionV2 = storage.read(localStorageWCSessionV2Key);
    if (sessionV2 != null && sessionV2['session'] != null) {
      Timer(const Duration(milliseconds: 500), () {
        wcV2Sessions.addAll(List.of(jsonDecode(sessionV2['session']))
            .map((e) => WCSessionDataV2.fromJson(Map<String, dynamic>.of({
                  'topic': e['topic'],
                  'peerMeta': e['peer']['metadata'],
                }))));
      });
    }
  }
}

class AccountCreate extends _AccountCreate with _$AccountCreate {}

abstract class _AccountCreate with Store {
  @observable
  String name = '';

  @observable
  String password = '';

  @observable
  String key = '';
}
