import 'package:app/pages/profile/index.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class CommunityPage extends StatefulWidget {
  CommunityPage(this.service);

  final AppService service;

  static final String route = '/profile/community';

  @override
  _CommunityPage createState() => _CommunityPage();
}

class _CommunityPage extends State<CommunityPage> {
  bool _loading = false;

  Future<void> _jumpToLink(String uri) async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    await UI.launchURL(uri);

    setState(() {
      _loading = false;
    });
  }

  void _onWechatTap() {
    showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            title: Text('Acala Wechat'),
            content: Image.asset('assets/images/public/aca_qr_wechat.jpg'),
            actions: [
              CupertinoButton(
                child: Text(
                  I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok'],
                  style: TextStyle(color: Colors.blueAccent),
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final colorGray = Theme.of(context).unselectedWidgetColor;
    final labelStyle = TextStyle(fontSize: 16);
    final contentStyle = TextStyle(fontSize: 14, color: colorGray);
    final pagePadding = 16.w;
    return Scaffold(
      appBar: AppBar(
          title: Text(dic['community']), centerTitle: true, leading: BackBtn()),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: <Widget>[
              RoundedCard(
                margin:
                    EdgeInsets.fromLTRB(pagePadding, 4.h, pagePadding, 16.h),
                padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 16.h),
                child: Column(
                  children: [
                    SettingsPageListItem(
                      label: 'Wechat',
                      onTap: _onWechatTap,
                    ),
                    Divider(),
                    SettingsPageListItem(
                      label: 'Twitter',
                      onTap: () =>
                          _jumpToLink('https://twitter.com/AcalaNetwork'),
                    ),
                    Divider(),
                    SettingsPageListItem(
                      label: 'Telegram',
                      onTap: () => _jumpToLink('https://t.me/acalaofficial'),
                    ),
                    Divider(),
                    SettingsPageListItem(
                      label: 'Discord',
                      onTap: () => _jumpToLink('https://discord.gg/6QHVY4X'),
                    ),
                    Divider(),
                    SettingsPageListItem(
                      label: 'LinkTree',
                      onTap: () =>
                          _jumpToLink('https://linktr.ee/acalanetwork'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
