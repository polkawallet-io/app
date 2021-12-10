import 'package:app/pages/profile/index.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
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

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final colorGray = Theme.of(context).unselectedWidgetColor;
    final labelStyle = TextStyle(fontSize: 16);
    final contentStyle = TextStyle(fontSize: 14, color: colorGray);
    final pagePadding = 16.w;
    return Scaffold(
      appBar: AppBar(
          title: Text(dic['community']),
          centerTitle: true,
          leading: BackBtn(onBack: () => Navigator.of(context).pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              RoundedCard(
                margin:
                    EdgeInsets.fromLTRB(pagePadding, 4.h, pagePadding, 16.h),
                padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 16.h),
                child: Column(
                  children: [
                    SettingsPageListItem(
                      label: dic['about.terms'],
                      onTap: () => _jumpToLink(
                          'https://polkawallet.io/terms-conditions.html'),
                    ),
                    Divider(),
                    SettingsPageListItem(
                      label: dic['about.privacy'],
                      onTap: () => _jumpToLink(
                          'https://github.com/polkawallet-io/app/blob/master/privacy-policy.md'),
                    ),
                    Divider(),
                    SettingsPageListItem(
                      label: 'Github',
                      onTap: () => _jumpToLink(
                          'https://github.com/polkawallet-io/app/issues'),
                    ),
                    Divider(),
                    SettingsPageListItem(
                      label: dic['about.feedback'],
                      content:
                          Text("hello@polkawallet.io", style: contentStyle),
                      onTap: () => _jumpToLink('mailto:hello@polkawallet.io'),
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
