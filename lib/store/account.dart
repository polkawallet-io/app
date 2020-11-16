import 'package:app/common/consts.dart';
import 'package:mobx/mobx.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/api/types/networkStateData.dart';

part 'account.g.dart';

class AccountStore extends _AccountStore with _$AccountStore {
  AccountStore(GetStorage storage) : super(storage);
}

abstract class _AccountStore with Store {
  _AccountStore(this.storage);

  final GetStorage storage;

  @observable
  AccountCreate newAccount = AccountCreate();

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
