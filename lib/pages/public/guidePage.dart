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
  final _pages = [0, 1, 2, 3];

  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final data = (ModalRoute.of(context).settings.arguments as Map);
    return WillPopScope(
        onWillPop: () async => false,
        child: Container(
            color: const Color(0xFF242528),
            child: Stack(alignment: Alignment.bottomCenter, children: [
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _pageIndex = index;
                  });
                },
                children: _pages
                    .map((e) => Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            Container(
                              padding: EdgeInsets.only(top: 95),
                              alignment: Alignment.topRight,
                              child: Image.asset(
                                'assets/images/public/guide_$e.png',
                                width: double.infinity,
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.only(
                                  right: 120, left: 16, bottom: 182),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dic['guide.title.$_pageIndex'],
                                    textAlign: TextAlign.start,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline1
                                        .copyWith(
                                            fontSize:
                                                UI.getTextSize(28, context),
                                            color: Colors.white,
                                            height: 1.15),
                                  ),
                                  Text(
                                    dic['guide.text.$_pageIndex'],
                                    textAlign: TextAlign.start,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline1
                                        .copyWith(
                                            fontSize:
                                                UI.getTextSize(18, context),
                                            color: Colors.white,
                                            fontWeight: FontWeight.w400),
                                  )
                                ],
                              ),
                            )
                          ],
                        ))
                    .toList(),
              ),
              Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: _pages
                          .map((i) => Container(
                                margin: EdgeInsets.only(right: 22),
                                height: 18,
                                width: 18,
                                decoration: BoxDecoration(
                                    color: i == _pageIndex
                                        ? Color(0xFFFFC952)
                                        : Color(0xFFD5D2CD),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(18))),
                              ))
                          .toList(),
                    )),
                Padding(
                    padding: EdgeInsets.fromLTRB(16, 36, 16, 48),
                    child: Button(
                      isDarkTheme: true,
                      title: _pageIndex + 1 >= _pages.length
                          ? dic['guide.enter']
                          : dic['guide.next'],
                      style: Theme.of(context)
                          .textTheme
                          .button
                          ?.copyWith(color: Colors.black),
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
