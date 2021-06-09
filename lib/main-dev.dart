import 'package:app/app.dart';
import 'package:app/common/consts.dart';
import 'package:app/common/types/pluginDisabled.dart';
import 'package:flutter/material.dart';
// import 'package:polkawallet_plugin_laminar/polkawallet_plugin_laminar.dart';
// import 'package:polkawallet_plugin_chainx/polkawallet_plugin_chainx.dart';
// import 'package:polkawallet_plugin_edgeware/polkawallet_plugin_edgeware.dart';

import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_kusama/polkawallet_plugin_kusama.dart';

void main() async {
  await GetStorage.init(get_storage_container);

  final _plugins = [
    PluginKusama(name: 'polkadot'),
    PluginKusama(),
    PluginAcala(),
    // PluginLaminar(),
    // PluginChainX(),
    // PluginEdgeware(),
  ];

  runApp(WalletApp(
      _plugins,
      [
        PluginDisabled(
            'chainx', Image.asset('assets/images/public/chainx_gray.png'))
      ],
      BuildTargets.dev));
}
