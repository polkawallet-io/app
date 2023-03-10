import 'package:app/pages/account/accountTypeSelectPage.dart';
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
    if (cachedURI != null && !cachedURI.contains('@2')) {
      wcSessionURI = cachedURI;

      final session = storage.read(localStorageWCSessionKey);
      if (session != null) {
        wcSession = WCProposerMeta.fromJson(session['peerMeta']);
      }
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
