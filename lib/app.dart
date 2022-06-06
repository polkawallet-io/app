import 'dart:async';

import 'package:app/common/components/willPopScopWrapper.dart';
import 'package:app/common/consts.dart';
import 'package:app/common/types/pluginDisabled.dart';
import 'package:app/pages/account/create/backupAccountPage.dart';
import 'package:app/pages/account/create/createAccountPage.dart';
import 'package:app/pages/account/createAccountEntryPage.dart';
import 'package:app/pages/assets/announcementPage.dart';
import 'package:app/pages/assets/asset/assetPage.dart';
import 'package:app/pages/assets/asset/locksDetailPage.dart';
import 'package:app/pages/assets/manage/manageAssetsPage.dart';
import 'package:app/pages/assets/transfer/detailPage.dart';
import 'package:app/pages/assets/transfer/transferPage.dart';
import 'package:app/pages/browser/browserPage.dart';
import 'package:app/pages/browser/dappLatestPage.dart';
import 'package:app/pages/ecosystem/completedPage.dart';
import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:app/pages/ecosystem/crosschainTransferPage.dart';
import 'package:app/pages/ecosystem/ecosystemPage.dart';
import 'package:app/pages/ecosystem/tokenStakingPage.dart';
import 'package:app/pages/homePage.dart';
import 'package:app/pages/networkSelectPage.dart';
import 'package:app/pages/pluginPage.dart';
import 'package:app/pages/profile/aboutPage.dart';
import 'package:app/pages/profile/account/accountManagePage.dart';
import 'package:app/pages/profile/account/changeNamePage.dart';
import 'package:app/pages/profile/account/changePasswordPage.dart';
import 'package:app/pages/profile/account/exportAccountPage.dart';
import 'package:app/pages/profile/account/exportResultPage.dart';
import 'package:app/pages/profile/account/signPage.dart';
import 'package:app/pages/profile/communityPage.dart';
import 'package:app/pages/profile/contacts/contactPage.dart';
import 'package:app/pages/profile/contacts/contactsPage.dart';
import 'package:app/pages/profile/message/messagePage.dart';
import 'package:app/pages/profile/recovery/createRecoveryPage.dart';
import 'package:app/pages/profile/recovery/friendListPage.dart';
import 'package:app/pages/profile/recovery/initiateRecoveryPage.dart';
import 'package:app/pages/profile/recovery/recoveryProofPage.dart';
import 'package:app/pages/profile/recovery/recoverySettingPage.dart';
import 'package:app/pages/profile/recovery/recoveryStatePage.dart';
import 'package:app/pages/profile/recovery/txDetailPage.dart';
import 'package:app/pages/profile/recovery/vouchRecoveryPage.dart';
import 'package:app/pages/profile/settings/remoteNodeListPage.dart';
import 'package:app/pages/profile/settings/settingsPage.dart';
import 'package:app/pages/public/DAppsTestPage.dart';
import 'package:app/pages/public/acalaBridgePage.dart';
import 'package:app/pages/public/guidePage.dart';
import 'package:app/pages/public/stakingDotGuide.dart';
import 'package:app/pages/public/stakingKSMGuide.dart';
import 'package:app/pages/walletConnect/walletConnectSignPage.dart';
import 'package:app/pages/walletConnect/wcPairingConfirmPage.dart';
import 'package:app/pages/walletConnect/wcSessionsPage.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/startPage.dart';
import 'package:app/store/index.dart';
import 'package:app/utils/UI.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/app.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';
import 'package:polkawallet_ui/pages/qrSenderPage.dart';
import 'package:polkawallet_ui/pages/qrSignerPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/pages/v3/accountListPage.dart';
import 'package:polkawallet_ui/pages/v3/plugin/pluginAccountListPage.dart';
import 'package:polkawallet_ui/pages/v3/txConfirmPage.dart';
import 'package:polkawallet_ui/pages/walletExtensionSignPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

import 'pages/account/import/importAccountCreatePage.dart';
import 'pages/account/import/importAccountFormKeyStore.dart';
import 'pages/account/import/importAccountFormMnemonic.dart';
import 'pages/account/import/importAccountFromRawSeed.dart';
import 'pages/account/import/selectImportTypePage.dart';

const get_storage_container = 'configuration';

bool _isInitialUriHandled = false;

class WalletApp extends StatefulWidget {
  WalletApp(this.plugins, this.disabledPlugins, BuildTargets buildTarget) {
    WalletApp.buildTarget = buildTarget;
  }
  final List<PolkawalletPlugin> plugins;
  final List<PluginDisabled> disabledPlugins;
  static BuildTargets buildTarget;
  static int isInitial = 0;

  static Future<void> checkUpdate(BuildContext context) async {
    final versions = await WalletApi.getLatestVersion();
    AppUI.checkUpdate(context, versions, WalletApp.buildTarget,
        autoCheck: true);
  }

  @override
  _WalletAppState createState() => _WalletAppState();
}

class _WalletAppState extends State<WalletApp> with WidgetsBindingObserver {
  final _analytics = FirebaseAnalytics();

  Keyring _keyring;

  AppStore _store;
  AppService _service;

  ThemeData _theme;

  Locale _locale;

  NetworkParams _connectedNode;

  BuildContext _homePageContext;
  PageRouteParams _autoRoutingParams;

  ThemeData _getAppTheme(MaterialColor color, {Color secondaryColor}) {
    return ThemeData(
      // backgroundColor: Color(0xFFF0ECE6),
      scaffoldBackgroundColor: Color(0xFFF5F3F0),
      dividerColor: Color(0xFFD4D4D4),
      cardColor: Colors.white,
      toggleableActiveColor: Color(0xFF768FE1),
      errorColor: Color(0xFFE46B41),
      unselectedWidgetColor: Color(0xFF858380),
      textSelectionTheme:
          TextSelectionThemeData(selectionColor: Color(0xFF565554)),
      appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFF5F3F0),
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Color(0xFF565554),
              fontSize: 18,
              fontFamily: 'TitilliumWeb',
              fontWeight: FontWeight.w600)),
      primarySwatch: color,
      hoverColor: secondaryColor,
      colorScheme: ColorScheme.fromSwatch().copyWith(),
      textTheme: TextTheme(
          headline1: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: Color(0xFF565554),
              fontFamily: "TitilliumWeb"),
          headline2: TextStyle(
            fontSize: 22,
          ),
          headline3: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF565554),
              fontFamily: "TitilliumWeb"),
          headline4: TextStyle(
            color: Color(0xFF565554),
            fontSize: 16,
            fontFamily: 'TitilliumWeb',
            fontWeight: FontWeight.w400,
          ),
          headline5: TextStyle(
            color: Color(0xFF565554),
            fontSize: 14,
            fontFamily: 'TitilliumWeb',
            fontWeight: FontWeight.w400,
          ),
          headline6: TextStyle(
            color: Color(0xFF565554),
            fontSize: 12,
            fontFamily: 'SF_Pro',
            fontWeight: FontWeight.w400,
          ),
          bodyText1: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF565554),
              fontFamily: "SF_Pro"),
          bodyText2: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: Color(0xFF565554),
              fontFamily: "SF_Pro"),
          caption: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: "TitilliumWeb"),
          button: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: "TitilliumWeb")),
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
      if (_locale != null) {
        _service.store.settings.initMessage((_locale).languageCode);
      }
    });
  }

  void _initWalletConnect() {
    _service.plugin.sdk.api.walletConnect.initClient((WCPairingData proposal) {
      print('get wc pairing');
      _handleWCPairing(proposal);
    }, (WCPairedData session) {
      print('get wc session');
      _service.store.account.createWCSession(session);
      _service.store.account.setWCPairing(false);
    }, (WCPayloadData payload) {
      print('get wc payload');
      _handleWCPayload(payload);
    });
  }

  Future<void> _handleWCPairing(WCPairingData pairingReq) async {
    final approved = await Navigator.of(context)
        .pushNamed(WCPairingConfirmPage.route, arguments: pairingReq);
    final address = _service.keyring.current.address;
    if (approved ?? false) {
      _service.store.account.setWCPairing(true);
      await _service.plugin.sdk.api.walletConnect
          .approvePairing(pairingReq, '$address@polkadot:acalatc5');
      print('wallet connect alive');
    } else {
      _service.plugin.sdk.api.walletConnect.rejectPairing(pairingReq);
    }
  }

  Future<void> _handleWCPayload(WCPayloadData payload) async {
    final res = await Navigator.of(context)
        .pushNamed(WalletConnectSignPage.route, arguments: payload);
    if (res == null) {
      print('user rejected signing');
      await _service.plugin.sdk.api.walletConnect
          .payloadRespond(payload, error: {
        'code': -32000,
        'message': "User rejected JSON-RPC request",
      });
    } else {
      print('user signed payload:');
      print(res);
      // await _service.plugin.sdk.api.walletConnect
      //     .payloadRespond(payload, response: );
    }
  }

  Future<void> _startPlugin(AppService service, {NetworkParams node}) async {
    // _initWalletConnect();

    setState(() {
      _connectedNode = null;
    });

    final connected = await service.plugin.start(_keyring,
        nodes: node != null ? [node] : service.plugin.nodeList);
    setState(() {
      _connectedNode = connected;
    });

    _dropsService(service, node: node);
  }

  Future<void> _restartWebConnect(AppService service,
      {NetworkParams node}) async {
    setState(() {
      _connectedNode = null;
    });

    // Offline JS interaction will be affected (import and export accounts)
    // final useLocalJS = WalletApi.getPolkadotJSVersion(
    //       _store.storage,
    //       service.plugin.basic.name,
    //       service.plugin.basic.jsCodeVersion,
    //     ) >
    //     service.plugin.basic.jsCodeVersion;

    // await service.plugin.beforeStart(
    //   _keyring,
    //   webView: _service?.plugin?.sdk?.webView,
    //   jsCode: useLocalJS
    //       ? WalletApi.getPolkadotJSCode(
    //           _store.storage, service.plugin.basic.name)
    //       : null,
    // );

    final connected = await service.plugin.start(_keyring,
        nodes: node != null ? [node] : service.plugin.nodeList);
    setState(() {
      _connectedNode = connected;
    });

    _dropsService(service, node: node);
  }

  Timer _webViewDropsTimer;
  Timer _dropsServiceTimer;
  Timer _chainTimer;
  _dropsService(AppService service, {NetworkParams node}) {
    _dropsServiceCancel();
    _dropsServiceTimer = Timer(Duration(seconds: 24), () async {
      _chainTimer = Timer(Duration(seconds: 18), () async {
        _restartWebConnect(service, node: node);
        _webViewDropsTimer = Timer(Duration(seconds: 60), () {
          _dropsService(service, node: node);
        });
      });
      _service.plugin.sdk.webView
          .evalJavascript('api.rpc.system.chain()')
          .then((value) => _dropsService(service, node: node));
    });
  }

  _dropsServiceCancel() {
    _dropsServiceTimer?.cancel();
    _chainTimer?.cancel();
    _webViewDropsTimer?.cancel();
  }

  Future<void> _changeNetwork(PolkawalletPlugin network,
      {NetworkParams node}) async {
    _dropsServiceCancel();
    setState(() {
      _connectedNode = null;
    });

    _keyring.setSS58(network.basic.ss58);

    setState(() {
      _theme = _getAppTheme(
        network.basic.primaryColor,
        secondaryColor: network.basic.gradientColor,
      );
    });
    _store.settings.setNetwork(network.basic.name);

    final useLocalJS = WalletApi.getPolkadotJSVersion(
          _store.storage,
          network.basic.name,
          network.basic.jsCodeVersion,
        ) >
        network.basic.jsCodeVersion;

    _service.plugin.dispose();

    final service = AppService(widget.plugins, network, _keyring, _store);
    service.init();

    // we reuse the existing webView instance when we start a new plugin.
    await network.beforeStart(_keyring,
        webView: _service?.plugin?.sdk?.webView,
        jsCode: useLocalJS
            ? WalletApi.getPolkadotJSCode(_store.storage, network.basic.name)
            : null, socketDisconnectedAction: () {
      UI.throttle(() {
        _dropsServiceCancel();
        _restartWebConnect(service, node: node);
      });
    });

    setState(() {
      _service = service;
    });

    _startPlugin(service, node: node);
  }

  Future<void> _switchNetwork(String networkName,
      {NetworkParams node, PageRouteParams pageRoute}) async {
    final isNetworkChanged = networkName != _service.plugin.basic.name;

    if (isNetworkChanged) {
      final confirmed = await showCupertinoDialog(
          context: _homePageContext,
          builder: (BuildContext context) {
            final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
            return CupertinoAlertDialog(
              title: Text(dic['v3.changeNetwork']),
              content: Container(
                margin: EdgeInsets.only(top: 24, bottom: 24),
                child: Text(
                    '${dic['v3.changeNetwork.confirm']} ${networkName.toUpperCase()} ?'),
              ),
              actions: [
                CupertinoButton(
                  child: Text(
                    I18n.of(context)
                        .getDic(i18n_full_dic_ui, 'common')['cancel'],
                    style: TextStyle(
                        color: Theme.of(context).unselectedWidgetColor),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoButton(
                  child: Text(
                    I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok'],
                    style: TextStyle(
                        color: Theme.of(context).toggleableActiveColor),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          });
      if (!confirmed) return;

      // display a dialog while changing network
      showCupertinoDialog(
          context: _homePageContext,
          builder: (_) {
            final dic =
                I18n.of(_homePageContext).getDic(i18n_full_dic_app, 'assets');
            return CupertinoAlertDialog(
              title: Text(dic['v3.changeNetwork']),
              content: Container(
                margin: EdgeInsets.only(top: 24, bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 8),
                      child: CupertinoActivityIndicator(),
                    ),
                    Text(
                        '${dic['v3.changeNetwork.ing']} ${networkName.toUpperCase()}...')
                  ],
                ),
              ),
            );
          });
    }

    await _changeNetwork(
        widget.plugins.firstWhere((e) => e.basic.name == networkName),
        node: node);
    await _service.store.assets.loadCache(_keyring.current, networkName);

    if (isNetworkChanged) {
      Navigator.of(_homePageContext).pop();
    }

    // set auto routing path so we can route to the page after network changed
    _autoRoutingParams = pageRoute;
  }

  Future<void> _changeNode(NetworkParams node) async {
    if (_connectedNode != null) {
      setState(() {
        _connectedNode = null;
      });
    }
    _service.plugin.sdk.api.account.unsubscribeBalance();
    final connected = await _service.plugin.start(_keyring, nodes: [node]);
    setState(() {
      _connectedNode = connected;
    });
  }

  Future<void> _checkBadAddressAndWarn(BuildContext context) async {
    if (_keyring != null &&
        _keyring.current != null &&
        _keyring.current.pubKey ==
            '0xda99a528d2cbe6b908408c4f887d2d0336394414a9edb474c33a690a4202341a') {
      final Map dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
      showCupertinoDialog(
          context: context,
          builder: (_) {
            return CupertinoAlertDialog(
              title: Text(dic['bad.warn']),
              content: Text(
                  '${Fmt.address(_keyring.current.address)} ${dic['bad.warn.info']}'),
              actions: [
                CupertinoButton(
                  child: Text(I18n.of(context)
                      .getDic(i18n_full_dic_ui, 'common')['ok']),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          });
    }
  }

  Future<void> _checkJSCodeUpdate(
      BuildContext context, PolkawalletPlugin plugin,
      {bool needReload = true}) async {
    _checkBadAddressAndWarn(context);
    // check js code update
    final jsVersions = await WalletApi.fetchPolkadotJSVersion();
    if (jsVersions == null) return;

    final network = plugin.basic.name;
    final version = jsVersions[network];
    final versionMin = jsVersions['$network-min'];
    final currentVersion = WalletApi.getPolkadotJSVersion(
      _store.storage,
      network,
      plugin.basic.jsCodeVersion,
    );
    print('js update: $network $currentVersion $version $versionMin');
    final bool needUpdate = await AppUI.checkJSCodeUpdate(
        context, _store.storage, currentVersion, version, versionMin, network);
    if (needUpdate) {
      final res =
          await AppUI.updateJSCode(context, _store.storage, network, version);
      if (needReload && res) {
        _changeNetwork(plugin);
      }
    }
  }

  Future<int> _startApp(BuildContext context) async {
    if (_keyring == null) {
      _keyring = Keyring();
      await _keyring
          .init(widget.plugins.map((e) => e.basic.ss58).toSet().toList());

      final storage = GetStorage(get_storage_container);
      final store = AppStore(storage);
      await store.init();

      // await _showGuide(context, storage);

      final pluginIndex = widget.plugins
          .indexWhere((e) => e.basic.name == store.settings.network);
      final service = AppService(widget.plugins,
          widget.plugins[pluginIndex > -1 ? pluginIndex : 0], _keyring, store);
      service.init();
      setState(() {
        _store = store;
        _service = service;
        _theme = _getAppTheme(
          service.plugin.basic.primaryColor,
          secondaryColor: service.plugin.basic.gradientColor,
        );
      });

      if (store.settings.localeCode.isNotEmpty) {
        _changeLang(store.settings.localeCode);
      } else {
        _changeLang(Localizations.localeOf(context).toString());
      }

      final useLocalJS = WalletApi.getPolkadotJSVersion(
            _store.storage,
            service.plugin.basic.name,
            service.plugin.basic.jsCodeVersion,
          ) >
          service.plugin.basic.jsCodeVersion;

      await service.plugin.beforeStart(_keyring,
          jsCode: useLocalJS
              ? WalletApi.getPolkadotJSCode(
                  _store.storage, service.plugin.basic.name)
              : null, socketDisconnectedAction: () {
        UI.throttle(() {
          _dropsServiceCancel();
          _restartWebConnect(service);
        });
      });

      if (_keyring.keyPairs.length > 0) {
        _store.assets.loadCache(_keyring.current, _service.plugin.basic.name);
      }

      _startPlugin(service);

      WalletApi.getTokenStakingConfig().then((value) {
        _store.settings.setTokenStakingConfig(value);
      });
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

      StartPage.route: (_) {
        _startApp(context);
        return StartPage();
      },

      /// basic pages
      HomePage.route: (_) => WillPopScopWrapper(
            Observer(
              builder: (BuildContext context) {
                final accountCreated =
                    _service?.store?.account?.accountCreated ?? false;

                _homePageContext = context;

                return FutureBuilder<int>(
                  future: _startApp(context),
                  builder: (_, AsyncSnapshot<int> snapshot) {
                    if (snapshot.hasData && _service != null) {
                      if (WalletApp.isInitial == 1) {
                        WalletApp.isInitial++;
                        _checkJSCodeUpdate(context, _service.plugin,
                            needReload: false);
                        WalletApp.checkUpdate(context);
                        _queryPluginsConfig();
                      }
                      return snapshot.data > 0
                          ? HomePage(_service, widget.plugins, _connectedNode,
                              _checkJSCodeUpdate, _switchNetwork, _changeNode)
                          : CreateAccountEntryPage(_service.plugin);
                    } else {
                      return Container(color: Theme.of(context).hoverColor);
                    }
                  },
                );
              },
            ),
          ),
      TxConfirmPage.route: (_) => TxConfirmPage(
            _service.plugin,
            _keyring,
            _service.account.getPassword,
            txDisabledCalls: _service.store.settings
                .getDisabledCalls(_service.plugin.basic.name),
          ),
      WalletExtensionSignPage.route: (_) => WalletExtensionSignPage(
          _service.plugin, _keyring, _service.account.getPassword),
      QrSenderPage.route: (_) => QrSenderPage(_service.plugin, _keyring),
      QrSignerPage.route: (_) => QrSignerPage(_service.plugin, _keyring),
      ScanPage.route: (_) => ScanPage(_service.plugin, _keyring),
      AccountListPage.route: (_) => AccountListPage(_service.plugin, _keyring),
      PluginAccountListPage.route: (_) =>
          PluginAccountListPage(_service.plugin, _keyring),
      AccountQrCodePage.route: (_) =>
          AccountQrCodePage(_service.plugin, _keyring),
      NetworkSelectPage.route: (_) => NetworkSelectPage(
          _service, widget.plugins, widget.disabledPlugins, _changeNetwork),
      WCPairingConfirmPage.route: (_) => WCPairingConfirmPage(_service),
      WCSessionsPage.route: (_) => WCSessionsPage(_service),
      WalletConnectSignPage.route: (_) =>
          WalletConnectSignPage(_service, _service.account.getPassword),
      GuidePage.route: (_) => GuidePage(),
      AcalaBridgePage.route: (_) => AcalaBridgePage(),
      StakingKSMGuide.route: (_) => StakingKSMGuide(_service),
      StakingDOTGuide.route: (_) => StakingDOTGuide(_service),

      /// account
      CreateAccountEntryPage.route: (_) =>
          CreateAccountEntryPage(_service.plugin),
      CreateAccountPage.route: (_) => CreateAccountPage(_service),
      BackupAccountPage.route: (_) => BackupAccountPage(_service),
      DAppWrapperPage.route: (_) => DAppWrapperPage(
            _service.plugin,
            _keyring,
            getPassword: _service.account.getPassword,
            checkAuth: _store.settings.checkDAppAuth,
            updateAuth: _store.settings.updateDAppAuth,
          ),
      SelectImportTypePage.route: (_) => SelectImportTypePage(_service),
      ImportAccountFormMnemonic.route: (_) =>
          ImportAccountFormMnemonic(_service),
      ImportAccountFromRawSeed.route: (_) => ImportAccountFromRawSeed(_service),
      ImportAccountFromRawSeed.route: (_) => ImportAccountFromRawSeed(_service),
      ImportAccountFormKeyStore.route: (_) =>
          ImportAccountFormKeyStore(_service),
      ImportAccountCreatePage.route: (_) => ImportAccountCreatePage(_service),

      /// assets
      AssetPage.route: (_) => AssetPage(_service),
      TransferDetailPage.route: (_) => TransferDetailPage(_service),
      TransferPage.route: (_) => TransferPage(_service),
      LocksDetailPage.route: (_) => LocksDetailPage(_service),
      ManageAssetsPage.route: (_) => ManageAssetsPage(_service),
      AnnouncementPage.route: (_) => AnnouncementPage(),
      // NodeSelectPage.route: (_) =>
      //     NodeSelectPage(_service, widget.plugins, _changeNetwork, _changeNode),

      /// profile
      SignMessagePage.route: (_) => SignMessagePage(_service),
      ContactsPage.route: (_) => ContactsPage(_service),
      ContactPage.route: (_) => ContactPage(_service),
      AboutPage.route: (_) => AboutPage(_service),
      AccountManagePage.route: (_) => AccountManagePage(_service),
      CommunityPage.route: (_) => CommunityPage(_service),
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
      TxDetailPage.route: (_) => TxDetailPage(_service),
      MessagePage.route: (_) => MessagePage(_service),

      PluginPage.route: (_) => PluginPage(_service),

      //browser
      BrowserPage.route: (_) => BrowserPage(_service),
      DappLatestPage.route: (_) => DappLatestPage(_service),
      //ecosystem
      TokenStaking.route: (_) => TokenStaking(_service),
      ConverToPage.route: (_) => ConverToPage(_service),
      CrossChainTransferPage.route: (_) => CrossChainTransferPage(_service),
      CompletedPage.route: (_) => CompletedPage(_service),
      EcosystemPage.route: (_) => EcosystemPage(_service),

      /// test
      DAppsTestPage.route: (_) => DAppsTestPage(),
    };
  }

  void _toPageByUri(Uri uri) {
    final paths = uri.toString().split("polkawallet.io");
    Map<dynamic, dynamic> args = Map<dynamic, dynamic>();
    if (paths.length > 1) {
      var network = "karura";
      final pathDatas = paths[1].split("?");
      if (pathDatas.length > 1) {
        final datas = pathDatas[1].split("&");
        datas.forEach((element) {
          if (element.split("=")[0] == "network") {
            network = Uri.decodeComponent(element.split("=")[1]);
          } else {
            args[element.split("=")[0]] =
                Uri.decodeComponent(element.split("=")[1]);
          }
        });
      }

      if (network != _service.plugin.basic.name) {
        _switchNetwork(network,
            pageRoute: PageRouteParams(pathDatas[0], args: args));
      } else {
        _autoRoutingParams = PageRouteParams(pathDatas[0], args: args);
        WidgetsBinding.instance.addPostFrameCallback((_) => _doAutoRouting());
      }
    }
  }

  void _handleIncomingAppLinks() {
    uriLinkStream.listen((Uri uri) {
      if (!mounted) return;
      closeWebView();
      _toPageByUri(uri);
      print('got uri: $uri');
    }, onError: (Object err) {
      if (!mounted) return;
      print('got err: $err');
    });
  }

  Future<void> _handleInitialAppLinks() async {
    if (!_isInitialUriHandled) {
      _isInitialUriHandled = true;
      print('_handleInitialUri called');
      try {
        final uri = await getInitialUri();
        if (uri == null) {
          print('no initial uri');
        } else {
          Timer.periodic(Duration(milliseconds: 1000), (timer) {
            if (WalletApp.isInitial > 0) {
              timer.cancel();
              _toPageByUri(uri);
            }
          });
          print('got initial uri: $uri');
        }
        if (!mounted) return;
      } on PlatformException {
        // Platform messages may fail but we ignore the exception
        print('falied to get initial uri');
      } on FormatException {
        if (!mounted) return;
        print('malformed initial uri');
      }
    }
  }

  void _setupPluginsNetworkSwitch() {
    widget.plugins.forEach((e) {
      if (e.appUtils.switchNetwork == null) {
        e.appUtils.switchNetwork =
            (String network, {PageRouteParams pageRoute}) async {
          _switchNetwork(network, pageRoute: pageRoute);
        };
      }
    });
  }

  void _doAutoRouting() {
    if (_autoRoutingParams != null) {
      print('page auto routing...');
      Navigator.of(_homePageContext).pushNamed(_autoRoutingParams.path,
          arguments: _autoRoutingParams.args);
      _autoRoutingParams = null;
    }
  }

  void _queryPluginsConfig() {
    WalletApi.getPluginsConfig(WalletApp.buildTarget).then((value) {
      _store.settings.setPluginsConfig(value);
    });
  }

  @override
  void initState() {
    super.initState();
    _handleIncomingAppLinks();
    _handleInitialAppLinks();
    WidgetsBinding.instance.addObserver(this);

    _setupPluginsNetworkSwitch();
  }

  @override
  void dispose() {
    _dropsServiceCancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        _dropsService(_service);
        break;
      case AppLifecycleState.paused:
        _dropsServiceCancel();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(_) {
    final routes = _getRoutes();

    /// we will do auto routing after plugin changed & app rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) => _doAutoRouting());

    return GestureDetector(
      onTapUp: (_) {
        FocusScope.of(context).focusedChild?.unfocus();
      },
      child: ScreenUtilInit(
          designSize: Size(390, 844),
          builder: () => MaterialApp(
                title: 'Polkawallet',
                builder: (context, widget) {
                  return MediaQuery(
                      data:
                          MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                      child: widget);
                },
                theme: _theme ??
                    _getAppTheme(
                      widget.plugins[0].basic.primaryColor,
                      secondaryColor: widget.plugins[0].basic.gradientColor,
                    ),
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
                initialRoute: StartPage.route,
                onGenerateRoute: (settings) => CupertinoPageRoute(
                    builder: routes[settings.name], settings: settings),
                navigatorObservers: [
                  FirebaseAnalyticsObserver(analytics: _analytics)
                ],
              )),
    );
  }
}
