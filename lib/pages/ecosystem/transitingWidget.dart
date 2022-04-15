import 'dart:math';

import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:rive/rive.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

class TransitingWidget extends StatefulWidget {
  TransitingWidget(this.fromNetwork, this.toNetwork, this.token, {Key key})
      : super(key: key);
  String fromNetwork;
  String toNetwork;
  String token;

  @override
  State<TransitingWidget> createState() => _TransitingWidgetState();
}

class _TransitingWidgetState extends State<TransitingWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(children: [
            Text(
              "${I18n.of(context)?.getDic(i18n_full_dic_app, 'public')['ecosystem.inTransiting']} ...",
              style: Theme.of(context).textTheme.headline1?.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: PluginColorsDark.headline1),
            ),
            Container(
              margin: EdgeInsets.only(top: 32),
              width: 290,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: Text(
                            "${widget.token} on ${widget.fromNetwork}",
                            style: Theme.of(context)
                                .textTheme
                                .headline3
                                ?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: PluginColorsDark.primary),
                          ))),
                  Transform.rotate(
                      angle: -pi,
                      child: SizedBox(
                          height: 14,
                          child: RiveAnimation.asset(
                            'assets/images/ecosystem_transiting_2.riv',
                            fit: BoxFit.contain,
                          ))),
                  Container(
                      margin: EdgeInsets.only(top: 17, bottom: 3),
                      height: 14,
                      child: RiveAnimation.asset(
                        'assets/images/ecosystem_transiting_1.riv',
                        fit: BoxFit.contain,
                      )),
                  Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        "${widget.token} on ${widget.toNetwork}",
                        style: Theme.of(context).textTheme.headline3?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: PluginColorsDark.headline1),
                      )),
                ],
              ),
            ),
          ]),
          Container(
            margin: EdgeInsets.only(left: 44),
            child: Image.asset("assets/images/ecosystem_transiting.png"),
          )
        ],
      ),
    );
  }
}
