import 'package:app/app.dart';
import 'package:app/common/consts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_bugly_play/flutter_bugly.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_bifrost/polkawallet_plugin_bifrost.dart';
import 'package:polkawallet_plugin_dbc/polkawallet_plugin_dbc.dart';
import 'package:polkawallet_plugin_edgeware/polkawallet_plugin_edgeware.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_kusama/polkawallet_plugin_kusama.dart';
import 'package:polkawallet_plugin_robonomics/polkawallet_plugin_robonomics.dart';
import 'package:polkawallet_plugin_statemine/polkawallet_plugin_statemine.dart';

import 'firebase_options.dart';

void main() async {
  // FlutterBugly.postCatchedException(() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await GetStorage.init(get_storage_container);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final plugins = [
    PluginKusama(name: 'polkadot'),
    PluginKusama(),
    PluginAcala(),
    PluginKarura(),
    PluginStatemine(),
    PluginStatemine(name: 'statemint'),
    PluginBifrost(),
    PluginEdgeware(),
    // PluginLaminar(),
    PluginDBC(),
    PluginRobonomics(),
  ];

  runApp(WalletApp(plugins, const [], BuildTargets.playStore));
  //   FlutterBugly.init(
  //     androidAppId: "64c2d01918",
  //     iOSAppId: "3803dd717e",
  //   );
  // });
}
