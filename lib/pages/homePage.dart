import 'package:app/pages/assets/index.dart';
import 'package:app/pages/profile/index.dart';
import 'package:app/pages/walletConnect/wcSessionsPage.dart';
import 'package:app/service/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_ui/ui.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class HomePage extends StatefulWidget {
  HomePage(this.service, this.connectedNode, this.checkJSCodeUpdate);

  final AppService service;
  final NetworkParams connectedNode;
  final Future<void> Function(BuildContext, PolkawalletPlugin,
      {bool needReload}) checkJSCodeUpdate;

  static final String route = '/';

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();

  int _tabIndex = 0;

  Future<void> _handleWalletConnect(String uri) async {
    print('wallet connect uri:');
    print(uri);
    await widget.service.plugin.sdk.api.walletConnect.connect(uri);
  }

  List<BottomNavigationBarItem> _buildNavItems(List<HomeNavItem> items) {
    return items.map((e) {
      final active = items[_tabIndex].text == e.text;
      return BottomNavigationBarItem(
        icon: SizedBox(
          child: active ? e.iconActive : e.icon,
          width: 32,
          height: 32,
        ),
        label: e.text,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final List<HomeNavItem> pages = [
      HomeNavItem(
        text: dic['assets'],
        icon: Padding(
          padding: EdgeInsets.all(2),
          child: SvgPicture.asset(
            'assets/images/wallet.svg',
            color: Theme.of(context).disabledColor,
          ),
        ),
        iconActive: Padding(
          padding: EdgeInsets.all(2),
          child: SvgPicture.asset(
            'assets/images/wallet.svg',
            color: Theme.of(context).primaryColor,
          ),
        ),
        content: AssetsPage(
            widget.service,
            widget.connectedNode,
            (PolkawalletPlugin plugin) =>
                widget.checkJSCodeUpdate(context, plugin),
            _handleWalletConnect),
        // content: Container(),
      )
    ];
    pages.addAll(
        widget.service.plugin.getNavItems(context, widget.service.keyring));
    pages.add(HomeNavItem(
      text: dic['profile'],
      icon: Padding(
        padding: EdgeInsets.all(2),
        child: SvgPicture.asset(
          'assets/images/user.svg',
          color: Theme.of(context).disabledColor,
        ),
      ),
      iconActive: Padding(
        padding: EdgeInsets.all(2),
        child: SvgPicture.asset(
          'assets/images/user.svg',
          color: Theme.of(context).primaryColor,
        ),
      ),
      content: ProfilePage(widget.service, widget.connectedNode),
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
                      height: 200,
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
          setState(() {
            _tabIndex = index;
          });
          _pageController.jumpToPage(index);
        },
        type: BottomNavigationBarType.fixed,
        items: _buildNavItems(pages),
      ),
    );
  }
}
