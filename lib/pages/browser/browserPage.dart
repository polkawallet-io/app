import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';

class BrowserPage extends StatefulWidget {
  BrowserPage({Key key}) : super(key: key);

  static final String route = '/browser';

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(dic['hub.broswer']),
          centerTitle: true,
        ),
        body: SafeArea(
            child: Column(
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.width * 184 / 390.0,
              child: Stack(
                children: [
                  Opacity(
                      opacity: 0.2,
                      child: Image.asset(
                        "assets/images/public/hub_browser.png",
                        width: double.infinity,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      )),
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${dic['hub.broswer'].toUpperCase()}",
                          style: Theme.of(context)
                              .textTheme
                              .headline1
                              ?.copyWith(
                                  color: PluginColorsDark.headline1,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold),
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(dic['hub.broswer.welcome'],
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(
                                        color: PluginColorsDark.headline1,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600))),
                        Container(
                          margin: EdgeInsets.only(left: 34, right: 34, top: 11),
                          padding: EdgeInsets.all(10),
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(0x80FFFFFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(dic['hub.broswer.search'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          ?.copyWith(
                                            color: PluginColorsDark.headline1,
                                            fontSize: 14,
                                          ))),
                              Icon(
                                Icons.search,
                                color: PluginColorsDark.headline1,
                                size: 20,
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 16, top: 20, right: 16, bottom: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PluginTextTag(
                        padding: EdgeInsets.zero,
                        title: dic['hub.broswer.latest'],
                        backgroundColor: PluginColorsDark.headline1,
                      ),
                      Image.asset(
                        "assets/images/browser_latest.png",
                        height: 10,
                      )
                    ],
                  ),
                  Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                      decoration: BoxDecoration(
                          color: Color(0xFFFFFFFF).withAlpha(18),
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8))))
                ],
              ),
            )
          ],
        )));
  }
}
