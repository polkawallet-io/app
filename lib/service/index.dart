import 'package:app/service/apiAccount.dart';
import 'package:app/service/apiAssets.dart';
import 'package:app/service/apiBridge.dart';
import 'package:app/service/apiWC.dart';
import 'package:app/store/index.dart';
import 'package:polkawallet_sdk/api/subscan.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/keyringEVM.dart';

class AppService {
  AppService(
      this.allPlugins, this.plugin, this.keyring, this.store, this.keyringEVM);

  final List<PolkawalletPlugin> allPlugins;
  PolkawalletPlugin plugin;
  final Keyring keyring;
  final KeyringEVM keyringEVM;
  final AppStore store;

  final subScan = SubScanApi();

  ApiAccount _account;
  ApiAssets _assets;
  ApiWC _wc;
  ApiBridge _bridge;

  ApiAccount get account => _account;
  ApiAssets get assets => _assets;
  ApiWC get wc => _wc;
  ApiBridge get bridge => _bridge;

  void init() {
    _account = ApiAccount(this);
    _assets = ApiAssets(this);
    _wc = ApiWC(this);
    _bridge = ApiBridge(this);
  }
}
