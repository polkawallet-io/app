import 'package:app/pages/assets.dart';
import 'package:app/pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_ui/ui.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class HomePage extends StatefulWidget {
  HomePage(this.plugin, this.keyring);

  final PolkawalletPlugin plugin;
  final Keyring keyring;

  static final String route = '/';

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();

  int _tabIndex = 0;

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
    final List<HomeNavItem> pages = [
      HomeNavItem(
        text: 'Assets',
        icon: SvgPicture.asset(
          'assets/images/wallet.svg',
          color: Theme.of(context).disabledColor,
        ),
        iconActive: SvgPicture.asset(
          'assets/images/wallet.svg',
          color: widget.plugin.primaryColor,
        ),
        content: AssetsPage(widget.plugin, widget.keyring),
      )
    ];
    pages.addAll(widget.plugin.getNavItems(widget.keyring));
    pages.add(HomeNavItem(
      text: 'Profile',
      icon: SvgPicture.asset(
        'assets/images/user.svg',
        color: Theme.of(context).disabledColor,
      ),
      iconActive: SvgPicture.asset(
        'assets/images/user.svg',
        color: widget.plugin.primaryColor,
      ),
      content: ProfilePage(widget.plugin, widget.keyring),
    ));
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _tabIndex = index;
          });
        },
        children: pages
            .map((e) => Scaffold(
                    body: PageWrapperWithBackground(SafeArea(
                  child: e.content,
                ))))
            .toList(),
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
