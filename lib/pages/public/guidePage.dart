import 'package:app/pages/homePage.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/button.dart';

class GuidePage extends StatefulWidget {
  static final String route = '/guide';

  @override
  _GuidePageState createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final PageController _pageController = PageController();
  final _pages = [0, 1, 2];

  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final data = (ModalRoute.of(context).settings.arguments as Map);
    return WillPopScope(
        onWillPop: () async => false,
        child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Stack(alignment: Alignment.bottomCenter, children: [
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _pageIndex = index;
                  });
                },
                children: _pages
                    .map(
                      (e) => Column(
                        children: [
                          Image.asset('assets/images/public/guide_$e.png')
                        ],
                      ),
                    )
                    .toList(),
              ),
              Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 44, left: 24, right: 24),
                    child: Text(
                      dic['guide.$_pageIndex'],
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.headline1.copyWith(
                          fontSize: UI.getTextSize(28, context), height: 1.15),
                    )),
                Padding(
                    padding: EdgeInsets.only(left: 27),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: _pages
                          .map((i) => Container(
                                margin: EdgeInsets.only(right: 19),
                                height: 17,
                                width: 17,
                                // child: Text("$_pageIndex"),
                                decoration: BoxDecoration(
                                    color: i == _pageIndex
                                        ? _pageIndex == 0
                                            ? Color(0xFFCE623C)
                                            : _pageIndex == 1
                                                ? Color(0xFFFFC952)
                                                : Color(0xFF768FE1)
                                        : Color(0xFFD5D2CD),
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(19 / 2.0))),
                              ))
                          .toList(),
                    )),
                Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 30),
                    child: Button(
                      title: _pageIndex + 1 >= _pages.length
                          ? dic['guide.enter']
                          : dic['guide.next'],
                      onPressed: () {
                        if (_pageIndex + 1 >= _pages.length) {
                          data["storage"].write(data["storeKey"], true);
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              HomePage.route, (route) => false);
                        } else {
                          _pageController.animateToPage(_pageIndex + 1,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.ease);
                        }
                      },
                    ))
              ])
            ])));
  }
}
