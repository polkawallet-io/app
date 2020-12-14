import 'package:mobx/mobx.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/api/types/recoveryInfo.dart';

part 'account.g.dart';

class AccountStore extends _AccountStore with _$AccountStore {
  AccountStore(GetStorage storage) : super(storage);
}

abstract class _AccountStore with Store {
  _AccountStore(this.storage);

  final GetStorage storage;

  @observable
  AccountCreate newAccount = AccountCreate();

  @observable
  ObservableMap<int, Map<String, String>> pubKeyAddressMap =
      ObservableMap<int, Map<String, String>>();

  @observable
  ObservableMap<String, String> addressIconsMap =
      ObservableMap<String, String>();

  @observable
  RecoveryInfo recoveryInfo = RecoveryInfo();

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
  void setAccountRecoveryInfo(Map json) {
    recoveryInfo = json != null ? RecoveryInfo.fromJson(json) : RecoveryInfo();
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
