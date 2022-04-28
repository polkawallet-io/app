import 'package:app/pages/browser/broswerApi.dart';
import 'package:app/pages/browser/search.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart' hide SearchDelegate;
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/consts.dart';

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
          onTap: () => close(context, ""),
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

  // 搜索到内容了
  @override
  Widget buildResults(BuildContext context) {
    BrowserApi.addDappSearchHistory(service, query);
    return Container(
      child: Center(
        child: Text("搜索的结果：$query"),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    var dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final searchHistory = BrowserApi.getDappSearchHistory(service);
    List<String> suggestionList = [];
    List<int> indexStart = [];
    if (query.isNotEmpty) {
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
                            color: PluginColorsDark.primary, fontSize: 12)),
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
                            fontSize: 14, color: PluginColorsDark.headline1)),
                    TextSpan(
                        text: suggestionList[index].substring(
                            indexStart.length > 0 ? indexStart[index] : 0,
                            indexStart.length > 0
                                ? indexStart[index] + query.length
                                : 0),
                        style: Theme.of(context).textTheme.headline6?.copyWith(
                            fontSize: 14, color: PluginColorsDark.primary)),
                    TextSpan(
                        text: suggestionList[index].substring(
                            indexStart.length > 0
                                ? indexStart[index] + query.length
                                : 0,
                            suggestionList[index].length),
                        style: Theme.of(context).textTheme.headline6?.copyWith(
                            fontSize: 14, color: PluginColorsDark.headline1))
                  ],
                )),
              ),
              onTap: () {
                query = suggestionList[index];
                // Scaffold.of(context).showSnackBar(SnackBar(content: Text(query)));
              },
            );
          },
        ))
      ],
    );
  }
}
