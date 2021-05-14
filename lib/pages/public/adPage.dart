import 'dart:async';

import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';

class AdPage extends StatefulWidget {
  static final String route = '/guide/ad';
  @override
  _AdPageState createState() => _AdPageState();
}

class _AdPageState extends State<AdPage> {
  int _timerCount = 10;

  void _updateTimer() {
    if (_timerCount > 0) {
      setState(() {
        _timerCount -= 1;
      });

      Timer(Duration(seconds: 1), () {
        _updateTimer();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();

    _updateTimer();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/public/kar_crowd_loan.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: 64, left: 24),
                child: Text('KARURA Parachain Auction',
                    style: TextStyle(
                        fontSize: 22,
                        color: Theme.of(context).cardColor,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 8, left: 24, right: 24),
                  child: KarCrowdLoanTitleSet(),
                ),
              ),
              Container(
                margin: EdgeInsets.all(24),
                child: RoundedButton(
                  text: '${dic['guide.enter']} (${_timerCount}s)',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class KarCrowdLoanTitleSet extends StatelessWidget {
  KarCrowdLoanTitleSet({this.finished = false});
  final bool finished;
  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final karColor = Colors.red;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 4, top: 2),
                child: Row(
                  children: [
                    Expanded(
                        child: FittedBox(
                            child: Text(
                                dic['auction.${finished ? 'finish' : 'live'}']
                                    .toUpperCase(),
                                style: TextStyle(
                                    color: karColor,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic))))
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 4, bottom: 2),
                child: Row(
                  children: [
                    Expanded(
                        child: FittedBox(
                            child: Text(
                                dic['auction.${finished ? 'finish' : 'live'}']
                                    .toUpperCase(),
                                style: TextStyle(
                                    color: cardColor,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic))))
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
