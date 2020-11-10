import 'package:app/pages/assets.dart';
import 'package:app/pages/homePage.dart';
import 'package:app/pages/profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/pages/accountListPage.dart';
import 'package:polkawallet_ui/pages/qrSenderPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';

class WalletApp extends StatefulWidget {
  WalletApp(this.plugins);
  final List<PolkawalletPlugin> plugins;
  @override
  _WalletAppState createState() => _WalletAppState(plugins[0]);
}

class _WalletAppState extends State<WalletApp> {
  _WalletAppState(PolkawalletPlugin defaultPlugin)
      : this._network = defaultPlugin;

  PolkawalletPlugin _network;
  final _keyring = Keyring();

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

  void _setNetwork(PolkawalletPlugin network) {
    setState(() {
      _network = network;
      _theme = _getAppTheme(network.primaryColor);
    });
  }

  void _setConnectedNode(NetworkParams node) {
    if (node != null) {
      _subscribeBalance();
    }
    setState(() {
      _connectedNode = node;
    });
  }

  void _subscribeBalance() async {
    KeyPairData acc = KeyPairData();
    if (_keyring.keyPairs.length > 0) {
      acc = _keyring.keyPairs[0];
    } else if (_keyring.externals.length > 0) {
      acc = _keyring.externals[0];
    } else {
      acc.address = '1CTthuNVHUxWJkejKUGAoKaW1ffbXaUUHpEQvfizWP2CMQe';
    }
    _network.subscribeBalances(acc);
  }

  Future<void> _startPlugin() async {
    await _keyring.init();

    final connected = await _network.start(_keyring);
    _setConnectedNode(connected);
  }

  void _showResult(BuildContext context, String title, res) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: SelectableText(res, textAlign: TextAlign.left),
          actions: [
            CupertinoButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  Map<String, Widget Function(BuildContext)> _getRoutes() {
    final res = _network != null ? _network.getRoutes(_keyring) : {};
    return {
      TxConfirmPage.route: (_) => TxConfirmPage(_network, _keyring),
      QrSenderPage.route: (_) => QrSenderPage(_network, _keyring),
      ScanPage.route: (_) => ScanPage(_network, _keyring),
      AccountListPage.route: (_) => AccountListPage(_network, _keyring),
      ...res,
    };
  }

  @override
  void initState() {
    super.initState();
    _startPlugin();
  }

  @override
  Widget build(BuildContext context) {
    final ProfilePage profile = ProfilePage(_network, _keyring);
    final AssetsPage assets = AssetsPage(_network, _keyring);
    return MaterialApp(
      title: 'Polkawallet Plugin Kusama Demo',
      theme: _theme ?? _getAppTheme(widget.plugins[0].primaryColor),
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
      home: MyHomePage(
        network: _network,
        keyring: _keyring,
        assetsContent: assets,
        profileContent: profile,
      ),
      routes: _getRoutes(),
    );
  }
}
