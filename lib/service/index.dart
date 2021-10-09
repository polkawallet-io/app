import 'package:app/common/consts.dart';
import 'package:app/service/apiAccount.dart';
import 'package:app/service/apiAssets.dart';
import 'package:app/store/index.dart';
import 'package:polkawallet_sdk/api/subscan.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/keyringETH.dart';

class AppService {
  AppService.init(this.allPlugins, this.plugin, this.keyring, this.keyringETH,
      this.store, this.buildTarget) {
    _account = ApiAccount(this);
    _assets = ApiAssets(this);
  }

  final List<PolkawalletPlugin> allPlugins;
  final PolkawalletPlugin plugin;
  final Keyring keyring;
  final KeyringETH keyringETH;
  final AppStore store;
  final BuildTargets buildTarget;

  final subScan = SubScanApi();

  ApiAccount _account;
  ApiAssets _assets;

  ApiAccount get account => _account;
  ApiAssets get assets => _assets;
}
