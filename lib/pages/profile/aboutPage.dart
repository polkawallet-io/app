import 'package:app/app.dart';
import 'package:app/pages/profile/index.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/UI.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/index.dart';

class AboutPage extends StatefulWidget {
  AboutPage(this.service);

  final AppService service;

  static final String route = '/profile/about';

  @override
  _AboutPage createState() => _AboutPage();
}

class _AboutPage extends State<AboutPage> {
  bool _loading = false;
  bool _updateLoading = false;
  String _appVersion;

  Future<void> _checkUpdate() async {
    if (_updateLoading) return;

    setState(() {
      _updateLoading = true;
    });
    final versions = await WalletApi.getLatestVersion();
    setState(() {
      _updateLoading = false;
    });
    AppUI.checkUpdate(context, versions, WalletApp.buildTarget);
  }

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
  void initState() {
    super.initState();
    getAppVersion();
  }

  getAppVersion() async {
    var appVersion = await Utils.getAppVersion();
    setState(() {
      _appVersion = appVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final currentJSVersion = WalletApi.getPolkadotJSVersion(
        widget.service.store.storage,
        widget.service.plugin.basic.name,
        widget.service.plugin.basic.jsCodeVersion);
    final colorGray = Theme.of(context).unselectedWidgetColor;
    final labelStyle = TextStyle(fontSize: 16);
    final contentStyle = TextStyle(fontSize: 14, color: colorGray);

    final pagePadding = 16.w;
    return Scaffold(
      appBar: AppBar(
          title: Text(dic['about.title']),
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
                    Divider(height: 24.h),
                    SettingsPageListItem(
                      label: dic['about.privacy'],
                      onTap: () => _jumpToLink(
                          'https://github.com/polkawallet-io/app/blob/master/privacy-policy.md'),
                    ),
                    Divider(height: 24.h),
                    SettingsPageListItem(
                      label: 'Github',
                      onTap: () => _jumpToLink(
                          'https://github.com/polkawallet-io/app/issues'),
                    ),
                    Divider(height: 24.h),
                    SettingsPageListItem(
                      label: dic['about.feedback'],
                      content:
                          Text("hello@polkawallet.io", style: contentStyle),
                      onTap: () => _jumpToLink('mailto:hello@polkawallet.io'),
                    ),
                  ],
                ),
              ),
              RoundedCard(
                margin:
                    EdgeInsets.fromLTRB(pagePadding, 8.h, pagePadding, 16.h),
                padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 16.h),
                child: Column(
                  children: [
                    SettingsPageListItem(
                      label: dic['about.version'],
                      content: Row(
                        children: [
                          Visibility(
                            visible: _updateLoading,
                            child: Container(
                              padding: EdgeInsets.only(right: 8.w),
                              child: CupertinoActivityIndicator(radius: 8.r),
                            ),
                          ),
                          Text(_appVersion ?? "", style: contentStyle)
                        ],
                      ),
                      onTap: _checkUpdate,
                    ),
                    Divider(height: 24.h),
                    SettingsPageListItem(
                      label: 'API',
                      content: Container(
                        padding: EdgeInsets.only(right: 8.w),
                        child: Text(currentJSVersion.toString(),
                            style: contentStyle),
                      ),
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
