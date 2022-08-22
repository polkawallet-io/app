import 'package:app/service/apiAccount.dart';
import 'package:app/service/apiAssets.dart';
import 'package:app/store/index.dart';
import 'package:polkawallet_sdk/api/subscan.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/keyringEVM.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';

class AppService {
  AppService(this.allPlugins, this.plugin, this.keyring, this.store,
      this.keyringEVM, this.pluginEvm);

  final List<PolkawalletPlugin> allPlugins;
  final PluginEvm pluginEvm;
  PolkawalletPlugin plugin;
  final Keyring keyring;
  final KeyringEVM keyringEVM;
  final AppStore store;

  final subScan = SubScanApi();

  ApiAccount _account;
  ApiAssets _assets;

  ApiAccount get account => _account;
  ApiAssets get assets => _assets;

  void init() {
    _account = ApiAccount(this);
    _assets = ApiAssets(this);
  }
}
