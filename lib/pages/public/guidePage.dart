import 'package:app/pages/homePage.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/button.dart';

class GuidePage extends StatefulWidget {
  static final String route = '/guide';

  @override
  _GuidePageState createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final PageController _pageController = PageController();
  final _pages = [0, 1, 2, 3, 4];

  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final data = (ModalRoute.of(context).settings.arguments as Map);
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
            backgroundColor: const Color(0xFF242528),
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              systemOverlayStyle: SystemUiOverlayStyle.light,
              backgroundColor: Colors.transparent,
            ),
            body: Stack(alignment: Alignment.bottomCenter, children: [
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _pageIndex = index;
                  });
                },
                children: _pages
                    .map((e) => Container(
                          alignment: Alignment.topRight,
                          margin: EdgeInsets.only(
                              bottom: 140 /
                                  844.0 *
                                  MediaQuery.of(context).size.height),
                          child: Image.asset(
                            'assets/images/public/guide_${e}_${I18n.of(context).locale.toString()}.png',
                            width: double.infinity,
                          ),
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
                    padding: EdgeInsets.fromLTRB(
                        16,
                        36 / 844.0 * MediaQuery.of(context).size.height,
                        16,
                        48 / 844.0 * MediaQuery.of(context).size.height),
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
