import 'dart:async';

import 'package:app/app.dart';
import 'package:app/common/consts.dart';
import 'package:app/pages/homePage.dart';
import 'package:app/pages/public/guidePage.dart';
import 'package:app/utils/Utils.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rive/rive.dart';

import 'store/settings.dart';

class StartPage extends StatefulWidget {
  StartPage({Key key}) : super(key: key);
  SettingsStore settings;
  // Function onDispose;

  static final String route = '/startPage';

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with SingleTickerProviderStateMixin {
  // AnimationController _con;
  // Animation _animation;
  Function toPage;
  Timer _timer;

  @override
  void initState() {
    super.initState();

    toPage = () {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(HomePage.route, (route) => false);
    };

    _showGuide(context, GetStorage(get_storage_container));

    _timer = Timer(Duration(milliseconds: 5000), () {
      toPage();
    });

    // _con = AnimationController(
    //     vsync: this, duration: Duration(milliseconds: 2000));
    // _animation = Tween(begin: 0.0, end: 1.0).animate(_con);
    //
    // _animation.addStatusListener((status) async {
    //   if (status == AnimationStatus.completed) {
    //     // widget.onDispose();
    //     toPage();
    //   }
    // });
    //
    // _con.forward(); //播放动画
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

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    // _con.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      // child: Center(
      //     child: RiveAnimation.asset(
      //   'assets/images/connecting.riv',
      // ))
      child: Center(
          child: Image.asset(
        "assets/images/logo_about.png",
        // "assets/images/opening.gif",
        fit: BoxFit.contain,
        width: 180,
      )),
    );
  }
}
