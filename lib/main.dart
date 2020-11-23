import 'package:app/app.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_kusama/polkawallet_plugin_kusama.dart';

import 'package:get_storage/get_storage.dart';

void main() async {
  await GetStorage.init(get_storage_container);

  final _plugins = [
    PluginKusama(name: 'polkadot'),
    PluginKusama(),
  ];

  runApp(WalletApp(_plugins));
}
