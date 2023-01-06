import 'package:app/service/apiAccount.dart';
import 'package:app/service/apiAssets.dart';
import 'package:app/service/apiBridge.dart';
import 'package:app/store/index.dart';
import 'package:polkawallet_sdk/api/subscan.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class AppService {
  AppService(this.allPlugins, this.plugin, this.keyring, this.store);

  final List<PolkawalletPlugin> allPlugins;
  final PolkawalletPlugin plugin;
  final Keyring keyring;
  final AppStore store;

  final subScan = SubScanApi();

  ApiAccount _account;
  ApiAssets _assets;
  ApiBridge _bridge;

  ApiAccount get account => _account;
  ApiAssets get assets => _assets;
  ApiBridge get bridge => _bridge;

  void init() {
    _account = ApiAccount(this);
    _assets = ApiAssets(this);
    _bridge = ApiBridge(this);
  }
}
