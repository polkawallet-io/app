import 'package:app/app.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_kusama/polkawallet_plugin_kusama.dart';

void main() {
  final _plugins = [
    PluginKusama(name: 'polkadot'),
    PluginKusama(),
  ];

  runApp(WalletApp(_plugins));
}
