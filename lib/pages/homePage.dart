import 'dart:convert';
import 'dart:io';

import 'package:app/common/consts.dart';
import 'package:app/pages/assets/index.dart';
import 'package:app/pages/profile/index.dart';
import 'package:app/pages/walletConnect/wcSessionsPage.dart';
import 'package:app/service/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:polkawallet_plugin_kusama/common/constants.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/ui.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class HomePage extends StatefulWidget {
  HomePage(this.service, this.connectedNode, this.checkJSCodeUpdate,
      this.switchNetwork);

  final AppService service;
  final NetworkParams connectedNode;
  final Future<void> Function(BuildContext, PolkawalletPlugin,
      {bool needReload}) checkJSCodeUpdate;
  final Future<void> Function(String) switchNetwork;

  static final String route = '/';

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  final _jPush = JPush();

  int _tabIndex = 0;

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
      await widget.switchNetwork(network);
    }
    if (tab != null) {
      final initialTab = int.parse(tab);
      _pageController.jumpToPage(initialTab);
      setState(() {
        _tabIndex = initialTab;
      });
    }
    // todo: we need to rebuild all module pages for this initial route
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
    final dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final List<HomeNavItem> pages = [
      HomeNavItem(
        text: dic['assets'],
        icon: SvgPicture.asset(
          'assets/images/nav_assets.svg',
          color: Theme.of(context).disabledColor,
        ),
        iconActive: SvgPicture.asset(
          'assets/images/nav_assets.svg',
          color: Theme.of(context).primaryColor,
        ),
        content: AssetsPage(
            widget.service,
            widget.connectedNode,
            (PolkawalletPlugin plugin) =>
                widget.checkJSCodeUpdate(context, plugin),
            () async => widget.switchNetwork(network_name_kusama),
            _handleWalletConnect),
        // content: Container(),
      )
    ];
    pages.addAll(
        widget.service.plugin.getNavItems(context, widget.service.keyring));
    pages.add(HomeNavItem(
      text: dic['profile'],
      icon: SvgPicture.asset(
        'assets/images/nav_profile.svg',
        color: Theme.of(context).disabledColor,
      ),
      iconActive: SvgPicture.asset(
        'assets/images/nav_profile.svg',
        color: Theme.of(context).primaryColor,
      ),
      content: ProfilePage(
        widget.service,
        widget.connectedNode,
        () async => widget.switchNetwork(network_name_kusama),
      ),
    ));
    return Scaffold(
      body: Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _tabIndex = index;
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
            return walletConnectAlive || walletConnecting
                ? Container(
                    margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height / 4),
                    child: FloatingActionButton(
                      backgroundColor: Theme.of(context).cardColor,
                      child: walletConnecting
                          ? CupertinoActivityIndicator()
                          : Image.asset(
                              'assets/images/wallet_connect_logo.png'),
                      onPressed: walletConnectAlive
                          ? () {
                              Navigator.of(context)
                                  .pushNamed(WCSessionsPage.route);
                            }
                          : () => null,
                    ),
                  )
                : Container();
          })
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        iconSize: 32,
        onTap: (index) {
          _pageController.jumpToPage(index);
          setState(() {
            _tabIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: _buildNavItems(pages),
      ),
    );
  }
}
