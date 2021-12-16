import 'package:app/app.dart';
import 'package:app/common/consts.dart';
import 'package:app/common/types/pluginDisabled.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/Utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_bifrost/polkawallet_plugin_bifrost.dart';
import 'package:polkawallet_plugin_edgeware/polkawallet_plugin_edgeware.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_kusama/polkawallet_plugin_kusama.dart';
import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  // await GetStorage.init(get_storage_container);
  await Firebase.initializeApp();
  var appVersionCode = await Utils.getBuildNumber();

  final plugins = [
    PluginKusama(name: 'polkadot'),
    PluginKusama(),
    PluginKarura(),
    PluginStatemine(),
    PluginAcala(),
    PluginBifrost(),
    // PluginChainX(),
    PluginEdgeware(),
    // PluginLaminar(),
  ];

  final pluginsConfig = await WalletApi.getPluginsConfig(BuildTargets.dev);
  if (pluginsConfig != null) {
    plugins.removeWhere((i) {
      final List disabled = pluginsConfig[i.basic.name]['disabled'];
      if (disabled != null) {
        return disabled.contains(appVersionCode) || disabled.contains(0);
      }
      return false;
    });
  }

  runApp(WalletApp(
      plugins,
      [
        PluginDisabled(
            'chainx', Image.asset('assets/images/public/chainx_gray.png'))
      ],
      BuildTargets.dev));
}
