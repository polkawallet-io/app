import 'package:app/pages/browser/broswerApi.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:polkawallet_ui/components/v3/plugin/PluginIconButton.dart';

class DappLatestPage extends StatefulWidget {
  DappLatestPage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static final String route = '/browser/latest';

  @override
  State<DappLatestPage> createState() => _DappLatestPageState();
}

class _DappLatestPageState extends State<DappLatestPage> {
  bool _isdelete = false;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final dappLatests = BrowserApi.getDappLatest(widget.service);
    return WillPopScope(
        onWillPop: () {
          if (_isdelete) {
            Navigator.of(context).pop(true);
          } else {
            Navigator.of(context).pop();
          }
          return Future.value();
        },
        child: PluginScaffold(
            appBar: PluginAppBar(
              title: Text(dic['hub.broswer.latest']),
              centerTitle: true,
              leading: PluginIconButton(
                icon: SvgPicture.asset(
                  "packages/polkawallet_ui/assets/images/icon_back_24.svg",
                  color: Colors.black,
                ),
                onPressed: () {
                  if (_isdelete) {
                    Navigator.of(context).pop(true);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            body: SafeArea(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                            onTap: () {
                              BrowserApi.deleteAllLatest(widget.service);
                              setState(() {
                                _isdelete = true;
                              });
                            },
                            child: Container(
                                child: Text(
                                  dic['hub.broswer.clearAll'],
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline5
                                      ?.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                    color: PluginColorsDark.primary,
                                    borderRadius: BorderRadius.circular(6)))),
                        Expanded(
                            child: ListView.separated(
                                padding: EdgeInsets.only(top: 16),
                                separatorBuilder: (context, index) =>
                                    Container(height: 8),
                                itemCount: dappLatests.length,
                                itemBuilder: (context, index) {
                                  final e = dappLatests[index];
                                  return Slidable(
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: PluginColorsDark.cardColor,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Row(
                                          children: [
                                            Container(
                                                width: 32,
                                                height: 32,
                                                margin:
                                                    EdgeInsets.only(right: 10),
                                                child: (e["icon"] as String)
                                                        .contains('.svg')
                                                    ? SvgPicture.network(
                                                        e["icon"])
                                                    : Image.network(e["icon"])),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  e["name"],
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headline5
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              PluginColorsDark
                                                                  .headline1,
                                                          height: 1.0),
                                                ),
                                                Text(e["detailUrl"],
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline6
                                                        ?.copyWith(
                                                            fontSize: 10,
                                                            color:
                                                                PluginColorsDark
                                                                    .green))
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                      endActionPane: ActionPane(
                                        extentRatio: 0.2,
                                        motion: ScrollMotion(),
                                        children: [
                                          SlidableAction(
                                            onPressed: (context) {
                                              BrowserApi.deleteLatest(
                                                  e, widget.service);
                                              setState(() {
                                                _isdelete = true;
                                              });
                                            },
                                            backgroundColor:
                                                PluginColorsDark.primary,
                                            foregroundColor: Colors.black,
                                            icon: Icons.delete,
                                          ),
                                        ],
                                      ));
                                }))
                      ],
                    )))));
  }
}
