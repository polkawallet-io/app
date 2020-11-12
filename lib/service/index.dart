import 'package:app/service/apiAccount.dart';
import 'package:app/store/index.dart';

import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/plugin/index.dart';

class AppService {
  AppService(this.plugin, this.keyring, this.store);

  final PolkawalletPlugin plugin;
  final Keyring keyring;
  final AppStore store;

  ApiAccount _account;

  ApiAccount get account => _account;

  void init() {
    _account = ApiAccount(this);
  }
}
