import 'package:app/pages/account/create/backupAccountPage.dart';
import 'package:app/pages/account/create/createAccountPage.dart';
import 'package:app/pages/account/createAccountEntryPage.dart';
import 'package:app/pages/account/import/importAccountPage.dart';
import 'package:app/pages/assets/asset/assetPage.dart';
import 'package:app/pages/assets/receive/receivePage.dart';
import 'package:app/pages/homePage.dart';
import 'package:app/pages/networkSelectPage.dart';
import 'package:app/service/index.dart';
import 'package:app/store/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_storage/get_storage.dart';

import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/pages/accountListPage.dart';
import 'package:polkawallet_ui/pages/qrSenderPage.dart';
import 'package:polkawallet_ui/pages/qrSignerPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';

class WalletApp extends StatefulWidget {
  WalletApp(this.plugins);
  final List<PolkawalletPlugin> plugins;
  @override
  _WalletAppState createState() => _WalletAppState();
}

class _WalletAppState extends State<WalletApp> {
  Keyring _keyring;

  AppStore _store;
  AppService _service;

  ThemeData _theme;

  Locale _locale;

  NetworkParams _connectedNode;

  ThemeData _getAppTheme(MaterialColor color) {
    return ThemeData(
      primarySwatch: color,
      textTheme: TextTheme(
          headline1: TextStyle(
            fontSize: 24,
          ),
          headline2: TextStyle(
            fontSize: 22,
          ),
          headline3: TextStyle(
            fontSize: 20,
          ),
          headline4: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          button: TextStyle(
            color: Colors.white,
            fontSize: 18,
          )),
    );
  }

  void _changeLang(String code) {
    Locale res;
    switch (code) {
      case 'zh':
        res = const Locale('zh', '');
        break;
      case 'en':
        res = const Locale('en', '');
        break;
      default:
        res = null;
    }
    setState(() {
      _locale = res;
    });
  }

  Future<void> _changeNetwork(PolkawalletPlugin network) async {
    _keyring.setSS58(network.basic.ss58);

    final service = AppService(network, _keyring, _store);
    service.init();
    setState(() {
      _service = service;
      _theme = _getAppTheme(network.basic.primaryColor);
      _connectedNode = null;
    });

    /// we reuse the existing webView instance when we start a new plugin.
    final connected =
        await network.start(_keyring, webView: _service.plugin.sdk.webView);
    setState(() {
      _connectedNode = connected;
    });
    _service.assets.fetchMarketPrice();
  }

  Future<int> _startPlugin() async {
    if (_keyring == null) {
      _keyring = Keyring();
      await _keyring.init();

      final storage = GetStorage('configuration');
      final store = AppStore(storage);
      await store.init();
      final service = AppService(widget.plugins[0], _keyring, store);
      service.init();
      setState(() {
        _store = store;
        _service = service;
      });

      final connected = await service.plugin.start(_keyring);
      setState(() {
        _connectedNode = connected;
      });
      _service.assets.fetchMarketPrice();
    }

    return _keyring.keyPairs.length;
  }

  Map<String, Widget Function(BuildContext)> _getRoutes() {
    final pluginPages = _service != null && _service.plugin != null
        ? _service.plugin.getRoutes(_keyring)
        : {};
    return {
      HomePage.route: (context) => FutureBuilder<int>(
            future: _startPlugin(),
            builder: (_, AsyncSnapshot<int> snapshot) {
              if (snapshot.hasData && _service != null) {
                return snapshot.data > 0
                    ? HomePage(_service, _connectedNode)
                    : CreateAccountEntryPage();
              } else {
                return Container();
              }
            },
          ),
      TxConfirmPage.route: (_) => TxConfirmPage(_service.plugin, _keyring),
      QrSenderPage.route: (_) => QrSenderPage(_service.plugin, _keyring),
      QrSignerPage.route: (_) => QrSignerPage(_service.plugin, _keyring),
      ScanPage.route: (_) => ScanPage(_service.plugin, _keyring),
      AccountListPage.route: (_) => AccountListPage(_service.plugin, _keyring),
      NetworkSelectPage.route: (_) =>
          NetworkSelectPage(_service, widget.plugins, _changeNetwork),
      ReceivePage.route: (_) => ReceivePage(_service),
      AssetPage.route: (_) => AssetPage(_service),

      /// account
      CreateAccountEntryPage.route: (_) => CreateAccountEntryPage(),
      CreateAccountPage.route: (_) => CreateAccountPage(_service),
      BackupAccountPage.route: (_) => BackupAccountPage(_service),
      ImportAccountPage.route: (_) => ImportAccountPage(_service),

      /// pages of plugin
      ...pluginPages,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polkawallet Plugin Kusama Demo',
      theme: _theme ?? _getAppTheme(widget.plugins[0].basic.primaryColor),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizationsDelegate(_locale ?? Locale('en', '')),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''),
        const Locale('zh', ''),
      ],
      initialRoute: HomePage.route,
      routes: _getRoutes(),
    );
  }
}
