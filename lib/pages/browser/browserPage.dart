import 'package:app/pages/browser/broswerApi.dart';
import 'package:app/pages/browser/browserSearch.dart';
import 'package:app/pages/browser/dappLatestPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:app/pages/browser/search.dart' as search;

class BrowserPage extends StatefulWidget {
  BrowserPage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static final String route = '/browser';

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  int _tag = 0;

  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final dapps = _tag == 0
        ? widget.service.store.settings.dapps
        : widget.service.store.settings.dapps
            .where((e) => e["tag"]
                .join(" #")
                .contains(widget.service.store.settings.dappAllTags[_tag - 1]))
            .toList();
    var dappLatests = BrowserApi.getDappLatest(widget.service);
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(dic['hub.browser']),
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
                          "${dic['hub.browser'].toUpperCase()}",
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
                            child: Text(dic['hub.browser.welcome'],
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(
                                        color: PluginColorsDark.headline1,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600))),
                        GestureDetector(
                            onTap: () async {
                              final result = await search.showSearch(
                                  context: context,
                                  delegate: SearchBarDelegate(widget.service,
                                      searchFieldLabel:
                                          dic['hub.browser.search'],
                                      searchFieldStyle: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          ?.copyWith(
                                              color: Color(0x80FFFFFF))));
                              if (result != null) {
                                setState(() {});
                              }
                            },
                            child: Container(
                              margin:
                                  EdgeInsets.only(left: 34, right: 34, top: 11),
                              padding: EdgeInsets.all(10),
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(0x80FFFFFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text(dic['hub.browser.search'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline5
                                              ?.copyWith(
                                                color:
                                                    PluginColorsDark.headline1,
                                                fontSize: 14,
                                              ))),
                                  Icon(
                                    Icons.search,
                                    color: PluginColorsDark.headline1,
                                    size: 20,
                                  )
                                ],
                              ),
                            ))
                      ],
                    ),
                  )
                ],
              ),
            ),
            Expanded(
                child: Container(
              margin: EdgeInsets.only(left: 16, top: 20, right: 16, bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Visibility(
                      visible: dappLatests.length > 0,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            PluginTextTag(
                              padding: EdgeInsets.zero,
                              title: dic['hub.browser.latest'],
                              backgroundColor: PluginColorsDark.headline1,
                            ),
                            GestureDetector(
                                onTap: () async {
                                  final re = await Navigator.of(context)
                                      .pushNamed(DappLatestPage.route);
                                  if (re != null) {
                                    setState(() {});
                                  }
                                },
                                child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 3),
                                    child: Image.asset(
                                      "assets/images/browser_latest.png",
                                      height: 10,
                                    )))
                          ],
                        ),
                        Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 14),
                            margin: EdgeInsets.only(bottom: 25),
                            decoration: BoxDecoration(
                                color: Color(0xFFFFFFFF).withAlpha(18),
                                borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8))),
                            child: Container(
                                height: 73,
                                width: double.infinity,
                                child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    separatorBuilder: (context, index) =>
                                        Container(width: 12),
                                    itemCount: dappLatests.length,
                                    itemBuilder: (context, index) {
                                      final e = dappLatests[index];
                                      return GestureDetector(
                                          onTap: () {
                                            BrowserApi.openBrowser(
                                                context, e, widget.service);
                                            setState(() {});
                                          },
                                          child: Container(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                    width: 50,
                                                    height: 50,
                                                    margin: EdgeInsets.only(
                                                        bottom: 5),
                                                    child: (e["icon"] as String)
                                                            .contains('.svg')
                                                        ? SvgPicture.network(
                                                            e["icon"])
                                                        : Image.network(
                                                            e["icon"])),
                                                Text(
                                                  e["name"],
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headline4
                                                      ?.copyWith(
                                                          color:
                                                              PluginColorsDark
                                                                  .headline1,
                                                          fontSize: 12),
                                                )
                                              ],
                                            ),
                                          ));
                                    })))
                      ])),
                  PluginTextTag(
                    padding: EdgeInsets.zero,
                    title: dic['hub.browser.fastPass'],
                    backgroundColor: PluginColorsDark.headline1,
                  ),
                  Container(
                      margin: EdgeInsets.only(top: 14, bottom: 18),
                      height: 22,
                      width: double.infinity,
                      child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          separatorBuilder: (context, index) =>
                              Container(width: 6),
                          itemCount:
                              widget.service.store.settings.dappAllTags.length +
                                  1,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                                onTap: () {
                                  if (_tag != index) {
                                    setState(() {
                                      _tag = index;
                                    });
                                  }
                                },
                                child: Container(
                                    child: Text(
                                      index == 0
                                          ? "all"
                                          : widget.service.store.settings
                                              .dappAllTags[index - 1],
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          ?.copyWith(
                                              fontSize: 10,
                                              fontWeight: _tag == index
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: _tag == index
                                                  ? Colors.black
                                                  : PluginColorsDark.headline1),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: _tag == index
                                            ? PluginColorsDark.primary
                                            : Color(0xFFFFFFFF).withAlpha(43),
                                        borderRadius:
                                            BorderRadius.circular(6))));
                          })),
                  Expanded(
                      child: GridView.builder(
                          itemCount: dapps.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16.0,
                                  crossAxisSpacing: 18.0,
                                  childAspectRatio: 170.0 / 48),
                          itemBuilder: (BuildContext context, int index) {
                            final dapp = dapps[index];
                            return GestureDetector(
                                onTap: () {
                                  BrowserApi.openBrowser(
                                      context, dapp, widget.service);
                                  setState(() {});
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Color(0x24FFFFFF),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      Container(
                                          width: 32,
                                          height: 32,
                                          margin: EdgeInsets.only(right: 8),
                                          child: (dapp["icon"] as String)
                                                  .contains('.svg')
                                              ? SvgPicture.network(dapp["icon"])
                                              : Image.network(dapp["icon"])),
                                      Expanded(
                                          child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            dapp["name"],
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline5
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: PluginColorsDark
                                                        .headline1,
                                                    height: 1),
                                          ),
                                          Text("#${dapp["tag"].join(" #")}",
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline5
                                                  ?.copyWith(
                                                      fontSize: 10,
                                                      color: PluginColorsDark
                                                          .headline1)),
                                        ],
                                      ))
                                    ],
                                  ),
                                ));
                          }))
                ],
              ),
            ))
          ],
        )));
  }
}
