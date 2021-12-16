import 'dart:async';

import 'package:app/app.dart';
import 'package:app/common/consts.dart';
import 'package:app/pages/homePage.dart';
import 'package:app/pages/public/guidePage.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/UI.dart';
import 'package:app/utils/Utils.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rive/rive.dart';

import 'store/settings.dart';

class StartPage extends StatefulWidget {
  StartPage({Key key}) : super(key: key);
  SettingsStore settings;

  static final String route = '/startPage';

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with SingleTickerProviderStateMixin {
  Function toPage;
  RiveAnimationController _controller;
  bool get isPlaying => _controller.isActive;

  @override
  void initState() {
    super.initState();

    _controller = OneShotAnimation(
      'Animation 1',
      onStop: () {
        toPage();
        _checkUpdate(context);
      },
    );

    toPage = () {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(HomePage.route, (route) => false);
    };

    _showGuide(context, GetStorage(get_storage_container));
  }

  Future<void> _showGuide(BuildContext context, GetStorage storage) async {
    final storeKey = '${show_guide_status_key}_${await Utils.getAppVersion()}';
    final showGuideStatus = storage.read(storeKey);
    if (showGuideStatus == null) {
      toPage = () async {
        Navigator.of(context).pushNamedAndRemoveUntil(
            GuidePage.route, (route) => false,
            arguments: {"storeKey": storeKey, "storage": storage});
      };
    }
  }

  Future<void> _checkUpdate(BuildContext context) async {
    final versions = await WalletApi.getLatestVersion();
    AppUI.checkUpdate(context, versions, WalletApp.buildTarget,
        autoCheck: true);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Container(
              margin: EdgeInsets.symmetric(horizontal: 70),
              child: RiveAnimation.asset(
                'assets/images/start_logo.riv',
                animations: const ['Animation 1'],
                controllers: [_controller],
              ))),
    );
  }
}
