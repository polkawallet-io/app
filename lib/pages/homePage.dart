import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/common/consts.dart';
import 'package:app/pages/assets/index.dart';
import 'package:app/pages/browser/browserPage.dart';
import 'package:app/pages/ecosystem/tokenStakingPage.dart';
import 'package:app/pages/pluginPage.dart';
import 'package:app/pages/profile/index.dart';
import 'package:app/pages/walletConnect/wcSessionsPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/BottomNavigationBar.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/utils/app.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/metaHubPage.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginItemCard.dart';
import 'package:polkawallet_ui/ui.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';

class HomePage extends StatefulWidget {
  HomePage(this.service, this.plugins, this.connectedNode,
      this.checkJSCodeUpdate, this.switchNetwork, this.changeNode);

  final AppService service;
  final NetworkParams connectedNode;
  final Future<void> Function(BuildContext, PolkawalletPlugin,
      {bool needReload}) checkJSCodeUpdate;
  final Future<void> Function(String,
      {NetworkParams node, PageRouteParams pageRoute}) switchNetwork;

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
  Timer _wssNotifyTimer;

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

      _setupWssNotifyTimer();
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

  Future<void> _setupWssNotifyTimer() async {
    if (_wssNotifyTimer != null) {
      _wssNotifyTimer.cancel();
    }

    _wssNotifyTimer = Timer(Duration(seconds: 60), () {
      if (mounted && widget.connectedNode == null) {
        showCupertinoDialog(
            context: context,
            builder: (_) {
              return PolkawalletAlertDialog(
                content: Text(I18n.of(context)
                    .getDic(i18n_full_dic_app, 'public')['wss.timeout']),
              );
            });
        Timer(Duration(seconds: 5), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
      _wssNotifyTimer = null;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context).settings.arguments as Map;
      if (args != null && args['tab'] != null) {
        setState(() {
          _tabIndex = args['tab'];
        });
      }
      _setupJPush();
      _setupWssNotifyTimer();
      widget.service.store.settings.initDapps();
    });
  }

  List<Color> getMetaHubColors() {
    switch (widget.service.plugin.basic.name) {
      case para_chain_name_karura:
        return [Color(0xFFE40C5B), Color(0xFFFF4C3B)];
      case para_chain_name_acala:
        return [Color(0xFFFF2B1B), Color(0xFF665AFF)];
      case relay_chain_name_dot:
        return [Color(0xFFE91384), Color(0xFFB6238C)];
      case relay_chain_name_ksm:
        return [Color(0xFFFFFFFF), Color(0x9EFFFFFF)];
      case chain_name_edgeware:
        return [Color(0xFF21C1D5), Color(0xFF057AA9)];
      case chain_name_dbc:
        return [Color(0xFF5BC1D3), Color(0xFF374BD4)];
      default:
        return [Theme.of(context).primaryColor, Theme.of(context).hoverColor];
    }
  }

  MetaHubItem buildMetaHubBrowser() {
    var dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    return MetaHubItem(
        dic['hub.browser'],
        GestureDetector(
          child: Column(children: [
            Expanded(
                child: SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset('assets/images/public/hub_browser.png'),
                  Container(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      dic['hub.cover.browser'],
                      textAlign: TextAlign.justify,
                      style: Theme.of(context).textTheme.headline4.copyWith(
                          fontSize: UI.getTextSize(14, context),
                          color: Colors.white),
                    ),
                  )
                ],
              ),
            )),
            Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Color.fromARGB(36, 255, 255, 255),
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                alignment: AlignmentDirectional.center,
                child: Text(
                  dic['hub.enter'],
                  style: Theme.of(context).textTheme.headline1.copyWith(
                      fontSize: UI.getTextSize(20, context),
                      color: Theme.of(context).errorColor),
                ))
          ]),
          onTap: () {
            Navigator.of(context).pushNamed(BrowserPage.route);
          },
        ));
  }

  MetaHubItem buildMetaHubEcosystem() {
    var dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    var token = "DOT";
    if (widget.service.plugin.basic.name == relay_chain_name_ksm ||
        widget.service.plugin.basic.name == para_chain_name_karura ||
        widget.service.plugin.basic.name == para_chain_name_bifrost ||
        widget.service.plugin.basic.name == para_chain_name_statemine) {
      token = "KSM";
    }
    if (!widget.service.store.settings.tokenStakingConfig["onStart"][token]) {
      return null;
    }
    return MetaHubItem(
        "${token.toUpperCase()} ${dic['hub.staking']}",
        GestureDetector(
          child: Column(children: [
            Expanded(
                child: SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset(
                      'assets/images/public/hub_token_staking_$token.png'),
                  Container(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      dic['hub.cover.tokenStaking'],
                      textAlign: TextAlign.justify,
                      style: Theme.of(context).textTheme.headline4.copyWith(
                          fontSize: UI.getTextSize(14, context),
                          color: Colors.white),
                    ),
                  )
                ],
              ),
            )),
            Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Color.fromARGB(36, 255, 255, 255),
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                alignment: AlignmentDirectional.center,
                child: Text(
                  dic['hub.enter'],
                  style: Theme.of(context).textTheme.headline1.copyWith(
                      fontSize: UI.getTextSize(20, context),
                      color: Theme.of(context).errorColor),
                ))
          ]),
          onTap: () {
            if (token == "DOT") {
              if (widget.service.plugin.basic.name != para_chain_name_acala) {
                widget.service.plugin.appUtils.switchNetwork(
                  para_chain_name_acala,
                  pageRoute: PageRouteParams(TokenStaking.route,
                      args: {"token": token}),
                );
                return;
              }
            } else {
              if (widget.service.plugin.basic.name != para_chain_name_karura) {
                widget.service.plugin.appUtils.switchNetwork(
                  para_chain_name_karura,
                  pageRoute: PageRouteParams(TokenStaking.route,
                      args: {"token": token}),
                );
                return;
              }
            }
            Navigator.of(context).pushNamed(
              TokenStaking.route,
              arguments: {"token": token},
            );
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    final List<HomeNavItem> pages = [
      HomeNavItem(
        text: I18n.of(context).getDic(i18n_full_dic_app, 'assets')['assets'],
        icon: Image.asset(
          "assets/images/icon_assets_nor${UI.isDarkTheme(context) ? "_dark" : ""}.png",
          fit: BoxFit.contain,
        ),
        iconActive: Image.asset(
          "assets/images/icon_assets_sel${UI.isDarkTheme(context) ? "_dark" : ""}.png",
          fit: BoxFit.contain,
        ),
        content:
            AssetsPage(widget.service, widget.plugins, widget.connectedNode,
                (PolkawalletPlugin plugin) async {
          _setupWssNotifyTimer();
          widget.checkJSCodeUpdate(context, plugin);
        }, (String name, {NetworkParams node}) async {
          _setupWssNotifyTimer();
          widget.switchNetwork(name, node: node);
        }, _handleWalletConnect),
        // content: Container(),
      )
    ];
    final pluginPages =
        widget.service.plugin.getNavItems(context, widget.service.keyring);
    if (pluginPages.length > 1 ||
        (pluginPages.length == 1 && pluginPages[0].isAdapter)) {
      final List<MetaHubItem> items = [];
      if (widget.service.store.settings.dapps.length > 0) {
        items.add(buildMetaHubBrowser());
      }
      final ecosystemItem = buildMetaHubEcosystem();
      if (ecosystemItem != null) {
        items.add(buildMetaHubEcosystem());
      }
      pluginPages.forEach((element) {
        if (element.isAdapter) {
          items.add(MetaHubItem(element.text, element.content));
        } else {
          var dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
          final metaHubCovers = ['staking', 'governance', 'parachains', 'nft'];
          final coversZh = ['质押', '治理', '平行链'];
          metaHubCovers.addAll(coversZh);
          final coverIndex = metaHubCovers.indexOf(element.text.toLowerCase());
          final coverName = coverIndex > 3
              ? metaHubCovers[coverIndex - 4]
              : element.text.toLowerCase();
          items.add(MetaHubItem(
              element.text,
              GestureDetector(
                child: Column(
                  children: coverIndex > -1
                      ? [
                          Expanded(
                              child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Image.asset(
                                    'assets/images/public/hub_$coverName.png'),
                                Container(
                                  padding: EdgeInsets.only(top: 16),
                                  child: Text(
                                    dic['hub.cover.$coverName'],
                                    textAlign: TextAlign.justify,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline4
                                        .copyWith(
                                            fontSize:
                                                UI.getTextSize(14, context),
                                            color: Colors.white),
                                  ),
                                )
                              ],
                            ),
                          )),
                          Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Color.fromARGB(36, 255, 255, 255),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4))),
                              alignment: AlignmentDirectional.center,
                              child: Text(
                                dic['hub.enter'],
                                style: Theme.of(context)
                                    .textTheme
                                    .headline1
                                    .copyWith(
                                        fontSize: UI.getTextSize(20, context),
                                        color: Theme.of(context).errorColor),
                              ))
                        ]
                      : [
                          PluginItemCard(
                            margin: EdgeInsets.only(bottom: 16),
                            title: element.text,
                          )
                        ],
                ),
                onTap: element.onTap != null
                    ? element.onTap
                    : () {
                        Navigator.of(context).pushNamed(
                          PluginPage.route,
                          arguments: {
                            "title": element.text,
                            'body': element.content
                          },
                        );
                      },
              )));
        }
      });
      pages.add(HomeNavItem(
          content: MetaHubPage(
            pluginName: widget.service.plugin.basic.name,
            metaItems: items,
            colors: getMetaHubColors(),
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
              .getDic(i18n_full_dic_app, 'public')['v3.metahub']));
    } else {
      pages.add(HomeNavItem(
          content: pluginPages[0].content,
          icon: Image.asset(
            "assets/images/compass.png",
            fit: BoxFit.contain,
          ),
          iconActive: Image.asset(
            "assets/images/compass.png",
            fit: BoxFit.contain,
          ),
          text: I18n.of(context)
              .getDic(i18n_full_dic_app, 'public')['v3.metahub']));
    }
    pages.add(HomeNavItem(
      text: I18n.of(context).getDic(i18n_full_dic_app, 'profile')['title'],
      icon: Image.asset(
        "assets/images/icon_settings_30_nor${UI.isDarkTheme(context) ? "_dark" : ""}.png",
        fit: BoxFit.contain,
      ),
      iconActive: Image.asset(
        "assets/images/icon_settings_30_sel${UI.isDarkTheme(context) ? "_dark" : ""}.png",
        fit: BoxFit.contain,
      ),
      content: ProfilePage(widget.service, widget.connectedNode),
    ));
    return BottomBarScaffold(
      body: Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: [
          PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _tabIndex = index;
              });
            },
            children: pages
                .map((e) =>
                    widget.service.plugin.basic.name == para_chain_name_acala &&
                            e.text ==
                                I18n.of(context).getDic(
                                    i18n_full_dic_app, 'public')['v3.metahub']
                        ? e.content
                        : PageWrapperWithBackground(
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
                        ? CupertinoActivityIndicator(
                            color: const Color(0xFF3C3C44))
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
        });
      },
      pages: pages,
      tabIndex: _tabIndex,
      service: widget.service,
    );
  }
}
