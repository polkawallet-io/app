import 'package:app/service/index.dart';
import 'package:app/store/types/messageData.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/mainTabBar.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/index.dart';

class MessagePage extends StatefulWidget {
  MessagePage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static final String route = '/profile/message';

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  int _tabIndex = 0;
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    return Scaffold(
        appBar: AppBar(
          title: Text(dic['message']),
          centerTitle: true,
          leading: BackBtn(),
          actions: [
            Center(
                child: GestureDetector(
                    onTap: () {
                      widget.service.store.settings.readCommunityMessage([
                        ...(widget.service.store.settings.communityMessages[
                                widget.service.plugin.basic.name] ??
                            []),
                        ...(widget.service.store.settings
                                .communityMessages['all'] ??
                            [])
                      ], widget.service.plugin.basic.name);
                      widget.service.store.settings.readSystmeMessage(
                          widget.service.store.settings.systemMessages,
                          widget.service.plugin.basic.name);
                    },
                    child: Container(
                      padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 3),
                      height: 28,
                      margin: EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        image: DecorationImage(
                            image: AssetImage("assets/images/icon_bg_2.png"),
                            fit: BoxFit.fill),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        dic['message.readAll'],
                        style: TextStyle(
                          color: UI.isDarkTheme(context)
                              ? Colors.white
                              : Theme.of(context).cardColor,
                          fontSize: UI.getTextSize(12, context),
                          fontFamily: UI.getFontFamily('TitilliumWeb', context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )))
          ],
        ),
        body: Column(
          children: [
            Observer(builder: (_) {
              final communityUnreadNumber = (widget
                              .service.store.settings.communityUnreadNumber[
                          widget.service.plugin.basic.name] ??
                      0) +
                  (widget.service.store.settings.communityUnreadNumber['all'] ??
                      0);
              final systemUnreadNumber =
                  widget.service.store.settings.systemUnreadNumber;
              return Padding(
                  padding: EdgeInsets.all(16),
                  child: MainTabBar(
                    tabs: {
                      dic['message.community']: communityUnreadNumber > 0,
                      dic['message.system']: systemUnreadNumber > 0
                    },
                    activeTab: _tabIndex,
                    onTap: (index) {
                      if (index != _tabIndex && mounted) {
                        setState(() {
                          _tabIndex = index;
                        });
                      }
                    },
                  ));
            }),
            Divider(
              height: 1,
              color: Colors.black.withAlpha(25),
            ),
            Expanded(
                child: Container(
              color: UI.isDarkTheme(context) ? Color(0xFF353638) : Colors.white,
              child: Observer(builder: (_) {
                final List<MessageData> datas = [];
                if (_tabIndex == 0) {
                  datas.addAll(widget.service.store.settings.communityMessages[
                          widget.service.plugin.basic.name] ??
                      []);
                  datas.addAll(
                      widget.service.store.settings.communityMessages['all'] ??
                          []);
                } else {
                  datas.addAll(widget.service.store.settings.systemMessages);
                }
                datas.sort((left, right) => right.time.compareTo(left.time));
                return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    itemCount: datas.length,
                    itemBuilder: (context, index) {
                      final data = datas[index];
                      if (widget.service.store.settings
                              .getReadMessage()[data.file] ==
                          null) {
                        Future.delayed(Duration(microseconds: 500), () {
                          _tabIndex == 0
                              ? widget.service.store.settings
                                  .readCommunityMessage(
                                      [data], widget.service.plugin.basic.name)
                              : widget.service.store.settings.readSystmeMessage(
                                  [data], widget.service.plugin.basic.name);
                        });
                      }

                      if (_tabIndex == 0) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 25, vertical: 10),
                          child: Column(
                            children: [
                              Text(
                                DateFormat("MM/dd yyyy HH:mm")
                                    .format(data.time),
                                style: Theme.of(context)
                                    .textTheme
                                    .headline6
                                    ?.copyWith(
                                        fontSize: UI.getTextSize(10, context),
                                        color: UI.isDarkTheme(context)
                                            ? Colors.white
                                            : Theme.of(context)
                                                .textTheme
                                                .headline1
                                                .color
                                                .withAlpha(66)),
                              ),
                              GestureDetector(
                                  onTap: () {
                                    data.onDetailAction(context);
                                  },
                                  child: RoundedCard(
                                    borderWidth: 0.5,
                                    color: UI.isDarkTheme(context)
                                        ? Color(0xFF444547)
                                        : Theme.of(context)
                                            .scaffoldBackgroundColor,
                                    margin: EdgeInsets.only(top: 22),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(8),
                                                topRight: Radius.circular(8)),
                                            child: CachedNetworkImage(
                                              width: double.infinity,
                                              imageUrl: data.urlByBanner(),
                                              placeholder: (context, url) =>
                                                  PluginLoadingWidget(),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Icon(Icons.error),
                                            )),
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(14),
                                          child: Text(
                                            data.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline6
                                                ?.copyWith(
                                                    fontSize: UI.getTextSize(
                                                        14, context),
                                                    fontWeight:
                                                        FontWeight.w500),
                                          ),
                                        )
                                      ],
                                    ),
                                  ))
                            ],
                          ),
                        );
                      }
                      return Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                        child: Column(
                          children: [
                            Text(
                              DateFormat("MM/dd yyyy HH:mm").format(data.time),
                              style: Theme.of(context)
                                  .textTheme
                                  .headline6
                                  ?.copyWith(
                                      fontSize: UI.getTextSize(10, context),
                                      color: UI.isDarkTheme(context)
                                          ? Colors.white
                                          : Theme.of(context)
                                              .textTheme
                                              .headline1
                                              .color
                                              .withAlpha(66)),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 22, right: 65),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      width: 42,
                                      height: 42,
                                      margin: EdgeInsets.only(right: 18),
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(21),
                                          child: Image.asset(
                                              "assets/images/message_icon.png"))),
                                  Expanded(
                                      child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dic['message.polkawalletTeam'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText1
                                            .copyWith(
                                                fontSize: UI.getTextSize(
                                                    14, context)),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: UI.isDarkTheme(context)
                                              ? Color(0x24FFFFFF)
                                              : Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(10),
                                            topRight: Radius.circular(10),
                                            bottomRight: Radius.circular(10),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0x30000000),
                                              blurRadius: 2.0,
                                              spreadRadius: 0.0,
                                              offset: Offset(
                                                1.0,
                                                1.0,
                                              ),
                                            )
                                          ],
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 11),
                                        margin: EdgeInsets.only(top: 10),
                                        child: Html(
                                          data: data.content,
                                          onLinkTap:
                                              (url, attributes, element) {
                                            UI.launchURL(url);
                                          },
                                          onAnchorTap:
                                              (url, attributes, element) {
                                            UI.launchURL(url);
                                          },
                                        ),
                                      )
                                    ],
                                  ))
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    });
              }),
            ))
          ],
        ));
  }
}
