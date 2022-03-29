import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/mainTabBar.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:intl/intl.dart';

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
                    onTap: () {},
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
                          color: Theme.of(context).cardColor,
                          fontSize: 12,
                          fontFamily: 'TitilliumWeb',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )))
          ],
        ),
        body: SafeArea(
            child: Column(
          children: [
            Observer(builder: (_) {
              final communityUnreadNumber =
                  widget.service.store.settings.communityUnreadNumber;
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
              color: Colors.white,
              child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  itemCount: _tabIndex == 0
                      ? widget.service.store.settings.communityMessages.length
                      : widget.service.store.settings.systemMessages.length,
                  itemBuilder: (context, index) {
                    final data = _tabIndex == 0
                        ? widget.service.store.settings.communityMessages[index]
                        : widget.service.store.settings.systemMessages[index];
                    Future.delayed(Duration(microseconds: 500), () {
                      widget.service.store.settings.readMessage([data]);
                    });

                    if (_tabIndex == 0) {
                      return GestureDetector(
                          onTap: () {
                            data.onLinkAction(context);
                          },
                          child: Container(
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
                                          fontSize: 10,
                                          color: Theme.of(context)
                                              .textSelectionTheme
                                              .selectionColor
                                              .withAlpha(66)),
                                ),
                                RoundedCard(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  margin: EdgeInsets.only(top: 22),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(10),
                                              topRight: Radius.circular(10)),
                                          child: Image.network(
                                            data.banner,
                                            width: double.infinity,
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
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ));
                    }
                    return Container();
                  }),
            ))
          ],
        )));
  }
}
