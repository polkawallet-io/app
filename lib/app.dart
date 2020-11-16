import 'package:app/pages/account/create/backupAccountPage.dart';
import 'package:app/pages/account/create/createAccountPage.dart';
import 'package:app/pages/account/createAccountEntryPage.dart';
import 'package:app/pages/account/import/importAccountPage.dart';
import 'package:app/pages/homePage.dart';
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
  _WalletAppState createState() => _WalletAppState(plugins[0]);
}

class _WalletAppState extends State<WalletApp> {
  _WalletAppState(PolkawalletPlugin defaultPlugin)
      : this._network = defaultPlugin;

  PolkawalletPlugin _network;
  Keyring _keyring;

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

  void _setNetwork(PolkawalletPlugin network) {
    setState(() {
      _network = network;
      _theme = _getAppTheme(network.primaryColor);
    });
  }

  Future<int> _startPlugin() async {
    print('start plugin');
    if (_keyring == null) {
      _keyring = Keyring();
      await _keyring.init();

      final storage = GetStorage('configuration');
      final store = AppStore(storage);
      await store.init();
      final service = AppService(_network, _keyring, store);
      service.init();
      setState(() {
        _service = service;
      });

      final connected = await _network.start(_keyring);
      setState(() {
        _connectedNode = connected;
      });
    }

    return _keyring.keyPairs.length;
  }

  // Future<int> _initStore(BuildContext context) async {
  //   if (_appStore == null) {
  //     _appStore = globalAppStore;
  //     print('initailizing app state');
  //     print('sys locale: ${Localizations.localeOf(context)}');
  //     await _appStore.init(Localizations.localeOf(context).toString());
  //
  //     // init webApi after store initiated
  //     webApi = Api(context, _appStore);
  //     webApi.init();
  //
  //     _changeLang(context, _appStore.settings.localeCode);
  //     _changeTheme();
  //
  //     _checkUpdate(context);
  //   }
  //   return _appStore.account.accountListAll.length;
  // }

  Map<String, Widget Function(BuildContext)> _getRoutes() {
    final pluginPages = _network != null ? _network.getRoutes(_keyring) : {};
    return {
      HomePage.route: (context) => FutureBuilder<int>(
            future: _startPlugin(),
            builder: (_, AsyncSnapshot<int> snapshot) {
              if (snapshot.hasData && _service != null) {
                return snapshot.data > 0
                    ? HomePage(_service)
                    : CreateAccountEntryPage();
              } else {
                return Container();
              }
            },
          ),
      TxConfirmPage.route: (_) => TxConfirmPage(_network, _keyring),
      QrSenderPage.route: (_) => QrSenderPage(_network, _keyring),
      QrSignerPage.route: (_) => QrSignerPage(_network, _keyring),
      ScanPage.route: (_) => ScanPage(_network, _keyring),
      AccountListPage.route: (_) => AccountListPage(_network, _keyring),

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
      theme: _theme ?? _getAppTheme(widget.plugins[0].primaryColor),
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
