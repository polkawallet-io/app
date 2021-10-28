import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';

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
    final size = MediaQuery.of(context).size;
    return new WillPopScope(
      onWillPop: () async => _pageIndex == 4,
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _pageIndex = index;
              });
            },
            children: _pages
                .map((e) => ListView(
                      children: [
                        Container(
                          margin:
                              EdgeInsets.only(top: size.height / 6, bottom: 8),
                          child:
                              Image.asset('assets/images/public/guide_$e.png'),
                          constraints:
                              BoxConstraints(maxHeight: size.height / 2),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dic['guide.$e'],
                                style: Theme.of(context).textTheme.headline4,
                              )
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _pages
                              .map((i) => Container(
                                    margin: EdgeInsets.all(4),
                                    height: 8,
                                    width: i == e ? 16 : 8,
                                    decoration: BoxDecoration(
                                        color: i == e
                                            ? Theme.of(context).primaryColor
                                            : Theme.of(context).disabledColor,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(8))),
                                  ))
                              .toList(),
                        ),
                        Visibility(
                            visible: e == 4,
                            child: Container(
                              margin: EdgeInsets.fromLTRB(24, 16, 24, 0),
                              child: RoundedButton(
                                text: dic['guide.enter'],
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                              ),
                            ))
                      ],
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
