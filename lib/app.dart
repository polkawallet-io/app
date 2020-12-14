import 'package:app/common/components/willPopScopWrapper.dart';
import 'package:app/pages/account/create/backupAccountPage.dart';
import 'package:app/pages/account/create/createAccountPage.dart';
import 'package:app/pages/account/createAccountEntryPage.dart';
import 'package:app/pages/account/import/importAccountPage.dart';
import 'package:app/pages/assets/asset/assetPage.dart';
import 'package:app/pages/assets/transfer/detailPage.dart';
import 'package:app/pages/assets/transfer/transferPage.dart';
import 'package:app/pages/homePage.dart';
import 'package:app/pages/networkSelectPage.dart';
import 'package:app/pages/profile/aboutPage.dart';
import 'package:app/pages/profile/account/accountManagePage.dart';
import 'package:app/pages/profile/account/changeNamePage.dart';
import 'package:app/pages/profile/account/changePasswordPage.dart';
import 'package:app/pages/profile/account/exportAccountPage.dart';
import 'package:app/pages/profile/account/exportResultPage.dart';
import 'package:app/pages/profile/contacts/contactPage.dart';
import 'package:app/pages/profile/contacts/contactsPage.dart';
import 'package:app/pages/profile/recovery/createRecoveryPage.dart';
import 'package:app/pages/profile/recovery/friendListPage.dart';
import 'package:app/pages/profile/recovery/initiateRecoveryPage.dart';
import 'package:app/pages/profile/recovery/recoveryProofPage.dart';
import 'package:app/pages/profile/recovery/recoverySettingPage.dart';
import 'package:app/pages/profile/recovery/recoveryStatePage.dart';
import 'package:app/pages/profile/recovery/vouchRecoveryPage.dart';
import 'package:app/pages/profile/settings/remoteNodeListPage.dart';
import 'package:app/pages/profile/settings/settingsPage.dart';
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
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/qrSenderPage.dart';
import 'package:polkawallet_ui/pages/qrSignerPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';

const get_storage_container = 'configuration';

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
    _service.store.settings.setLocalCode(code);

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

  Future<void> _startPlugin() async {
    setState(() {
      _connectedNode = null;
    });
    final connected = await _service.plugin.start(_keyring);
    setState(() {
      _connectedNode = connected;
    });
  }

  Future<void> _changeNetwork(PolkawalletPlugin network) async {
    _keyring.setSS58(network.basic.ss58);

    setState(() {
      _theme = _getAppTheme(network.basic.primaryColor);
    });
    _store.settings.setNetwork(network.basic.name);

    /// we reuse the existing webView instance when we start a new plugin.
    await network.beforeStart(_keyring, webView: _service.plugin.sdk.webView);

    final service = AppService(network, _keyring, _store);
    service.init();
    setState(() {
      _service = service;
    });

    _startPlugin();
    _service.assets.fetchMarketPrice();
  }

  Future<void> _changeNode(NetworkParams node) async {
    if (_connectedNode != null) {
      setState(() {
        _connectedNode = null;
      });
    }

    final connected =
        await _service.plugin.sdk.api.connectNode(_keyring, [node]);
    setState(() {
      _connectedNode = connected;
    });
  }

  Future<int> _startApp(BuildContext context) async {
    if (_keyring == null) {
      _keyring = Keyring();
      await _keyring.init();

      final storage = GetStorage(get_storage_container);
      final store = AppStore(storage);
      await store.init();
      final service = AppService(
          widget.plugins
              .firstWhere((e) => e.basic.name == store.settings.network),
          _keyring,
          store);
      service.init();
      setState(() {
        _store = store;
        _service = service;
        _theme = _getAppTheme(service.plugin.basic.primaryColor);
      });

      if (store.settings.localeCode.isNotEmpty) {
        _changeLang(store.settings.localeCode);
      } else {
        _changeLang(Localizations.localeOf(context).toString());
      }

      await service.plugin.beforeStart(_keyring);
      _startPlugin();
      _service.assets.fetchMarketPrice();
    }

    return _keyring.allAccounts.length;
  }

  Map<String, Widget Function(BuildContext)> _getRoutes() {
    final pluginPages = _service != null && _service.plugin != null
        ? _service.plugin.getRoutes(_keyring)
        : {};
    return {
      /// pages of plugin
      ...pluginPages,

      /// basic pages
      HomePage.route: (context) => WillPopScopWrapper(
            FutureBuilder<int>(
              future: _startApp(context),
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
          ),
      TxConfirmPage.route: (_) => TxConfirmPage(
          _service.plugin, _keyring, _service.account.getPassword),
      QrSenderPage.route: (_) => QrSenderPage(_service.plugin, _keyring),
      QrSignerPage.route: (_) => QrSignerPage(_service.plugin, _keyring),
      ScanPage.route: (_) => ScanPage(_service.plugin, _keyring),
      AccountListPage.route: (_) => AccountListPage(_service.plugin, _keyring),
      AccountQrCodePage.route: (_) =>
          AccountQrCodePage(_service.plugin, _keyring),
      NetworkSelectPage.route: (_) =>
          NetworkSelectPage(_service, widget.plugins, _changeNetwork),

      /// account
      CreateAccountEntryPage.route: (_) => CreateAccountEntryPage(),
      CreateAccountPage.route: (_) => CreateAccountPage(_service),
      BackupAccountPage.route: (_) => BackupAccountPage(_service),
      ImportAccountPage.route: (_) => ImportAccountPage(_service),

      /// assets
      AssetPage.route: (_) => AssetPage(_service),
      TransferDetailPage.route: (_) => TransferDetailPage(_service),
      TransferPage.route: (_) => TransferPage(_service),

      /// profile
      ContactsPage.route: (_) => ContactsPage(_service),
      ContactPage.route: (_) => ContactPage(_service),
      AboutPage.route: (_) => AboutPage(_service),
      AccountManagePage.route: (_) => AccountManagePage(_service),
      ChangeNamePage.route: (_) => ChangeNamePage(_service),
      ChangePasswordPage.route: (_) => ChangePasswordPage(_service),
      ExportAccountPage.route: (_) => ExportAccountPage(_service),
      ExportResultPage.route: (_) => ExportResultPage(),
      SettingsPage.route: (_) =>
          SettingsPage(_service, _changeLang, _changeNode),
      RemoteNodeListPage.route: (_) =>
          RemoteNodeListPage(_service, _changeNode),
      CreateRecoveryPage.route: (_) => CreateRecoveryPage(_service),
      FriendListPage.route: (_) => FriendListPage(_service),
      RecoverySettingPage.route: (_) => RecoverySettingPage(_service),
      RecoveryStatePage.route: (_) => RecoveryStatePage(_service),
      RecoveryProofPage.route: (_) => RecoveryProofPage(_service),
      InitiateRecoveryPage.route: (_) => InitiateRecoveryPage(_service),
      VouchRecoveryPage.route: (_) => VouchRecoveryPage(_service),
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
