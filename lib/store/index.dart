import 'package:app/store/account.dart';
import 'package:app/store/assets.dart';
import 'package:app/store/settings.dart';
import 'package:mobx/mobx.dart';
import 'package:get_storage/get_storage.dart';

class AppStore {
  AppStore(this.storage);

  final GetStorage storage;

  AccountStore account;
  SettingsStore settings;
  AssetsStore assets;

  @action
  Future<void> init() async {
    settings = SettingsStore(storage);
    await settings.init();
    account = AccountStore(storage);
    assets = AssetsStore(storage);
  }
}
