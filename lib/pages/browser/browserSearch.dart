import 'package:app/pages/browser/browserApi.dart';
import 'package:app/pages/browser/search.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart' hide SearchDelegate;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';
import 'package:polkawallet_ui/utils/index.dart';

class SearchBarDelegate extends SearchDelegate<String> {
  final AppService service;

  final String searchFieldLabel;

  final TextStyle searchFieldStyle;

  final InputDecorationTheme searchFieldDecorationTheme;

  final TextInputType keyboardType;

  final TextInputAction textInputAction;

  SearchBarDelegate(
    this.service, {
    this.searchFieldLabel,
    this.searchFieldStyle,
    this.searchFieldDecorationTheme,
    this.keyboardType,
    this.textInputAction = TextInputAction.search,
  }) : super(
            searchFieldLabel: searchFieldLabel,
            searchFieldStyle: searchFieldStyle,
            searchFieldDecorationTheme: searchFieldDecorationTheme,
            keyboardType: keyboardType,
            textInputAction: textInputAction);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      GestureDetector(
          onTap: () => close(context, this.result),
          child: Center(
              child: Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Text(
                    I18n.of(context)
                        .getDic(i18n_full_dic_karura, 'common')['cancel'],
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                        color: PluginColorsDark.headline1,
                        fontWeight: FontWeight.w600),
                  ))))
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return null;
  }

  @override
  Widget buildResults(BuildContext context) {
    print("buildResults====");
    BrowserApi.addDappSearchHistory(service, query);
    var dapps = service.store.settings.dapps;
    if (query.trim().isNotEmpty) {
      List<dynamic> _dapps = [];
      dapps.forEach((element) {
        if (element['name'].contains(query)) {
          element['nameIndex'] = element['name'].indexOf(query);
          _dapps.add(element);
        } else if (element['detailUrl'].contains(query)) {
          element['detailIndex'] = element['detailUrl'].indexOf(query);
          _dapps.add(element);
        }
      });
      dapps = _dapps;
    }
    if (dapps.length == 0 && query.trim().length > 0) {
      final url = query.startsWith("http") ? query : "https://$query";
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pushNamed(
          DAppWrapperPage.route,
          arguments: {"url": url, "isPlugin": true},
        );
      });
      query = "";
      showResults(context);
    }
    return dapps.length == 0
        ? ListTail(
            isEmpty: true,
            isLoading: false,
            color: PluginColorsDark.headline1,
          )
        : ListView.separated(
            padding: EdgeInsets.all(16),
            separatorBuilder: (context, index) => Container(height: 8),
            itemCount: dapps.length,
            itemBuilder: (context, index) {
              final e = dapps[index];
              return GestureDetector(
                  onTap: () {
                    BrowserApi.openBrowser(context, e, service);
                    this.result = "rrue";
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: PluginColorsDark.cardColor,
                        borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        Container(
                            width: 32,
                            height: 32,
                            margin: EdgeInsets.only(right: 10),
                            child: (e["icon"] as String).contains('.svg')
                                ? SvgPicture.network(e["icon"])
                                : Image.network(e["icon"])),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                                text: TextSpan(
                              children: [
                                TextSpan(
                                    text: e["name"].substring(
                                        0,
                                        e['nameIndex'] != null
                                            ? e['nameIndex']
                                            : 0),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline5
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: PluginColorsDark.headline1,
                                            height: 1.0)),
                                TextSpan(
                                    text: e["name"].substring(
                                        e['nameIndex'] != null
                                            ? e['nameIndex']
                                            : 0,
                                        e['nameIndex'] != null
                                            ? e['nameIndex'] + query.length
                                            : 0),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline5
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: PluginColorsDark.primary,
                                            height: 1.0)),
                                TextSpan(
                                    text: e["name"].substring(
                                        e['nameIndex'] != null
                                            ? e['nameIndex'] + query.length
                                            : 0,
                                        e["name"].length),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline5
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: PluginColorsDark.headline1,
                                            height: 1.0))
                              ],
                            )),
                            RichText(
                                text: TextSpan(
                              children: [
                                TextSpan(
                                    text: e["detailUrl"].substring(
                                        0,
                                        e['detailIndex'] != null
                                            ? e['detailIndex']
                                            : 0),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline6
                                        ?.copyWith(
                                            fontSize:
                                                UI.getTextSize(10, context),
                                            color: PluginColorsDark.green)),
                                TextSpan(
                                    text: e["detailUrl"].substring(
                                        e['detailIndex'] != null
                                            ? e['detailIndex']
                                            : 0,
                                        e['detailIndex'] != null
                                            ? e['detailIndex'] + query.length
                                            : 0),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline6
                                        ?.copyWith(
                                            fontSize:
                                                UI.getTextSize(10, context),
                                            color: PluginColorsDark.primary)),
                                TextSpan(
                                    text: e["detailUrl"].substring(
                                        e['detailIndex'] != null
                                            ? e['detailIndex'] + query.length
                                            : 0,
                                        e["detailUrl"].length),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline6
                                        ?.copyWith(
                                            fontSize:
                                                UI.getTextSize(10, context),
                                            color: PluginColorsDark.green))
                              ],
                            )),
                          ],
                        )
                      ],
                    ),
                  ));
            });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    var dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final searchHistory = BrowserApi.getDappSearchHistory(service);
    List<String> suggestionList = [];
    List<int> indexStart = [];
    if (query.trim().isNotEmpty) {
      searchHistory.forEach((element) {
        if (element.contains(query)) {
          suggestionList.add(element);
          indexStart.add(element.indexOf(query));
        }
      });
    } else {
      suggestionList = searchHistory;
    }
    return Column(
      children: [
        Container(
          height: 38,
          color: Color(0xFFFFFFFF).withAlpha(51),
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dic['hub.browser.searchingHistory'],
                  style: Theme.of(context)
                      .textTheme
                      .headline5
                      ?.copyWith(color: PluginColorsDark.headline1)),
              GestureDetector(
                  onTap: () {
                    BrowserApi.deleteAllSearchHistory(service);
                    if (this.refersh != null) {
                      this.refersh();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: PluginColorsDark.primary,
                        width: 2.0,
                      ),
                      borderRadius:
                          const BorderRadius.all(const Radius.circular(4.0)),
                    ),
                    child: Text(dic['hub.browser.clearAll'],
                        style: Theme.of(context).textTheme.headline5?.copyWith(
                            color: PluginColorsDark.primary,
                            fontSize: UI.getTextSize(12, context))),
                  ))
            ],
          ),
        ),
        Expanded(
            child: ListView.separated(
          separatorBuilder: (context, index) => Container(
            height: 1,
            color: Color(0xFFFFFFFF).withAlpha(36),
          ),
          itemCount: suggestionList.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              child: Container(
                height: 38,
                color: Color(0xFFFFFFFF).withAlpha(25),
                padding: EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: RichText(
                    text: TextSpan(
                  children: [
                    TextSpan(
                        text: suggestionList[index].substring(
                            0, indexStart.length > 0 ? indexStart[index] : 0),
                        style: Theme.of(context).textTheme.headline6?.copyWith(
                            fontSize: UI.getTextSize(14, context),
                            color: PluginColorsDark.headline1)),
                    TextSpan(
                        text: suggestionList[index].substring(
                            indexStart.length > 0 ? indexStart[index] : 0,
                            indexStart.length > 0
                                ? indexStart[index] + query.length
                                : 0),
                        style: Theme.of(context).textTheme.headline6?.copyWith(
                            fontSize: UI.getTextSize(14, context),
                            color: PluginColorsDark.primary)),
                    TextSpan(
                        text: suggestionList[index].substring(
                            indexStart.length > 0
                                ? indexStart[index] + query.length
                                : 0,
                            suggestionList[index].length),
                        style: Theme.of(context).textTheme.headline6?.copyWith(
                            fontSize: UI.getTextSize(14, context),
                            color: PluginColorsDark.headline1))
                  ],
                )),
              ),
              onTap: () {
                query = suggestionList[index];
                showResults(context);
              },
            );
          },
        ))
      ],
    );
  }
}
