import 'dart:convert';
import 'dart:io';

import 'package:app/common/consts.dart';
import 'package:app/pages/assets/index.dart';
import 'package:app/pages/profile/index.dart';
import 'package:app/pages/walletConnect/wcSessionsPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/BottomNavigationBar.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:polkawallet_plugin_kusama/common/constants.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/mainTabBar.dart';
import 'package:polkawallet_ui/ui.dart';

class HomePage extends StatefulWidget {
  HomePage(this.service, this.plugins, this.connectedNode,
      this.checkJSCodeUpdate, this.switchNetwork, this.changeNode);

  final AppService service;
  final NetworkParams connectedNode;
  final Future<void> Function(BuildContext, PolkawalletPlugin,
      {bool needReload}) checkJSCodeUpdate;
  final Future<void> Function(String) switchNetwork;

  final List<PolkawalletPlugin> plugins;
  final Future<void> Function(NetworkParams) changeNode;

  static final String route = '/';

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  final _jPush = JPush();

  int _tabIndex = 0;

  final PageController _metahubPageController = PageController();
  int _metahubTabIndex = 0;

  Future<void> _handleWalletConnect(String uri) async {
    print('wallet connect uri:');
    print(uri);
    // await widget.service.plugin.sdk.api.walletConnect.connect(uri);
  }

  Future<void> _setupJPush() async {
    _jPush.addEventHandler(
      onOpenNotification: (Map<String, dynamic> message) async {
        print('flutter onOpenNotification:');
        print(message);
        Map params;
        if (Platform.isIOS) {
          params = message['extras'];
        } else {
          params = message['extras']['cn.jpush.android.EXTRA'] != null
              ? jsonDecode(message['extras']['cn.jpush.android.EXTRA'])
              : null;
        }
        print(params);
        if (params != null) {
          _onOpenNotification(params);
        }
      },
    );

    _jPush.setup(
      appKey: JPUSH_APP_KEY,
      production: false,
      debug: true,
    );
    _jPush.applyPushAuthority(
        new NotificationSettingsIOS(sound: true, alert: true, badge: false));

    _jPush.getRegistrationID().then((rid) {
      print("flutter get registration id : $rid");
    });
  }

  Future<void> _onOpenNotification(Map params) async {
    final network = params['network'];
    final tab = params['tab'];
    if (network != null && network != widget.service.plugin.basic.name) {
      Navigator.popUntil(context, ModalRoute.withName('/'));
      await widget.switchNetwork(network);
    }
    if (tab != null) {
      final initialTab = int.parse(tab);
      _pageController.jumpToPage(initialTab);
      setState(() {
        _tabIndex = initialTab;
      });
    }
    // final route = params['route'];
    // print(route);
    // if (route != null) {
    //   Navigator.of(context).pushNamed(route);
    // }
  }

  List<BottomNavigationBarItem> _buildNavItems(List<HomeNavItem> items) {
    return items.map((e) {
      final active = items[_tabIndex].text == e.text;
      return BottomNavigationBarItem(
        icon: Container(
          padding: EdgeInsets.all(active ? 0 : 2),
          child: active ? e.iconActive : e.icon,
          width: 32,
          height: 32,
        ),
        label: e.text,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.service.account
          .checkBannerStatus(widget.service.keyring.current.pubKey);

      _setupJPush();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<HomeNavItem> pages = [
      HomeNavItem(
        text: I18n.of(context).getDic(i18n_full_dic_app, 'assets')['assets'],
        icon: Image.asset(
          "assets/images/icon_assets_nor.png",
          fit: BoxFit.contain,
        ),
        iconActive: Image.asset(
          "assets/images/icon_assets_sel.png",
          fit: BoxFit.contain,
        ),
        content: AssetsPage(
            widget.service,
            widget.plugins,
            widget.changeNode,
            widget.connectedNode,
            (PolkawalletPlugin plugin) =>
                widget.checkJSCodeUpdate(context, plugin),
            (String name) async => widget.switchNetwork(name),
            _handleWalletConnect),
        // content: Container(),
      )
    ];
    final pluginPages =
        widget.service.plugin.getNavItems(context, widget.service.keyring);
    var pluginPage = HomeNavItem(
        content: pluginPages[0].content,
        icon: Image.asset(
          "assets/images/compass.png",
          fit: BoxFit.contain,
        ),
        iconActive: Image.asset(
          "assets/images/compass.png",
          fit: BoxFit.contain,
        ),
        text:
            I18n.of(context).getDic(i18n_full_dic_app, 'public')['v3.metahub']);
    if (pluginPages.length > 1) {
      pluginPage = HomeNavItem(
          content: Scaffold(
            appBar: AppBar(
              title: Container(
                  child: MainTabBar(
                tabs: [pluginPages[0].text, pluginPages[1].text],
                activeTab: _metahubTabIndex,
                onTap: (index) {
                  setState(() {
                    _metahubPageController.jumpToPage(index);
                    _metahubTabIndex = index;
                  });
                },
              )),
              centerTitle: true,
            ),
            body: PageView(
              controller: _metahubPageController,
              onPageChanged: (index) {
                setState(() {
                  _metahubTabIndex = index;
                });
              },
              children: pluginPages
                  .map((e) => PageWrapperWithBackground(
                        e.content,
                        height: 220,
                        backgroundImage:
                            widget.service.plugin.basic.backgroundImage,
                      ))
                  .toList(),
            ),
          ),
          icon: Image.asset(
            "assets/images/compass.png",
            fit: BoxFit.contain,
          ),
          iconActive: Image.asset(
            "assets/images/compass.png",
            fit: BoxFit.contain,
          ),
          text: I18n.of(context)
              .getDic(i18n_full_dic_app, 'public')['v3.metahub']);
    }

    pages.add(pluginPage);
    pages.add(HomeNavItem(
      text: I18n.of(context).getDic(i18n_full_dic_app, 'profile')['title'],
      icon: Image.asset(
        "assets/images/icon_settings_30_nor.png",
        fit: BoxFit.contain,
      ),
      iconActive: Image.asset(
        "assets/images/icon_settings_30_sel.png",
        fit: BoxFit.contain,
      ),
      content: ProfilePage(
        widget.service,
        widget.connectedNode,
        () async => widget.switchNetwork(network_name_kusama),
      ),
    ));
    return BottomBarScaffold(
      body: Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _tabIndex = index;
                _metahubTabIndex = 0;
              });
            },
            children: pages
                .map((e) => PageWrapperWithBackground(
                      e.content,
                      height: 220,
                      backgroundImage:
                          widget.service.plugin.basic.backgroundImage,
                    ))
                .toList(),
          ),
          Observer(builder: (_) {
            final walletConnectAlive =
                widget.service.store.account.wcSessions.length > 0;
            final walletConnecting =
                widget.service.store.account.walletConnectPairing;
            return Visibility(
                visible: walletConnectAlive || walletConnecting,
                child: Container(
                  margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height / 4),
                  child: FloatingActionButton(
                    backgroundColor: Theme.of(context).cardColor,
                    child: walletConnecting
                        ? CupertinoActivityIndicator()
                        : Image.asset('assets/images/wallet_connect_logo.png'),
                    onPressed: walletConnectAlive
                        ? () {
                            Navigator.of(context)
                                .pushNamed(WCSessionsPage.route);
                          }
                        : () => null,
                  ),
                ));
          })
        ],
      ),
      onChanged: (index) {
        setState(() {
          _pageController.jumpToPage(index);
          _tabIndex = index;
          _metahubTabIndex = 0;
        });
      },
      pages: pages,
      tabIndex: _tabIndex,
    );
  }
}
