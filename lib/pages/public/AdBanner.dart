import 'dart:async';

import 'package:app/pages/public/karPreAuctionPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final startTime = DateTime.utc(2021, 3, 1, 0, 0, 0);
    final endTime = DateTime.utc(2021, 4, 11, 0, 0, 0);
    final now = DateTime.now().millisecondsSinceEpoch;
    final show = now > startTime.millisecondsSinceEpoch &&
        now < endTime.millisecondsSinceEpoch;

    final fullWidth = MediaQuery.of(context).size.width;
    final cardColor = Theme.of(context).cardColor;
    return Container(
      child: show
          ? Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Container(
                      margin: EdgeInsets.all(8),
                      child: GestureDetector(
                        child: Image.asset(
                            'assets/images/public/banner_kar_plo.png'),
                        onTap: () => Navigator.of(context)
                            .pushNamed(KarPreAuctionPage.route),
                      ),
                    ))
                  ],
                ),
                Container(
                  constraints: BoxConstraints(maxHeight: fullWidth / 4),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            margin:
                                EdgeInsets.only(left: 20, top: 20, bottom: 10),
                            child: CountdownPanel(
                              cardColor: Theme.of(context).cardColor,
                              cardTextColor: Colors.pink,
                              textColor: Colors.orangeAccent,
                              endTime: endTime,
                            ),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: fullWidth / 3 + 16,
                            margin: EdgeInsets.only(left: 24, right: 8),
                            child: Image.asset(
                                'assets/images/public/kar_logo.png'),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Parachain Auction',
                                style: TextStyle(
                                    color: cardColor,
                                    height: 0.9,
                                    fontSize: 14),
                              ),
                              Text(
                                'Pre-support',
                                style: TextStyle(
                                    color: cardColor,
                                    height: 0.9,
                                    fontSize: 14),
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                )
              ],
            )
          : null,
    );
  }
}

class CountdownPanel extends StatefulWidget {
  CountdownPanel({
    this.cardColor,
    this.cardTextColor,
    this.textColor,
    this.endTime,
  });

  final Color cardColor;
  final Color cardTextColor;
  final Color textColor;
  final DateTime endTime;

  @override
  _CountdownPanel createState() => _CountdownPanel();
}

class _CountdownPanel extends State<CountdownPanel> {
  Timer _timer;

  void _updateTime() {
    setState(() {
      _timer = Timer(Duration(seconds: 1), _updateTime);
    });
  }

  Widget _buildCard(String text) {
    return Container(
      margin: EdgeInsets.only(left: 4, right: 2),
      padding: EdgeInsets.only(left: 6, right: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        color: widget.cardColor,
      ),
      constraints: BoxConstraints(minWidth: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: widget.cardTextColor,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            fontFamily: 'BebasNeue'),
      ),
    );
  }

  String formatTime(int num) {
    final str = num.toString();
    return str.length == 1 ? '0$str' : str;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_timer != null) {
      _timer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final left = widget.endTime.difference(now);
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildCard(left.inDays.toString()),
          Text(
            'days',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: widget.textColor),
          ),
          _buildCard(
              '${formatTime(left.inHours % 24)}:${formatTime(left.inMinutes % 60)}:${formatTime(left.inSeconds % 60)}'),
          Text(
            'left',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: widget.textColor),
          ),
        ],
      ),
    );
  }
}
