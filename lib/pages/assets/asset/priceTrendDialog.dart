import 'package:app/pages/assets/asset/priceTrendChart.dart';
import 'package:app/pages/assets/asset/rewardsChart.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:orientation/orientation.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

class PriceTrendDialog extends StatefulWidget {
  PriceTrendDialog(this.data, this.symbol, this.priceCurrencySymbol, {Key key})
      : super(key: key);
  List<TimeSeriesAmount> data;
  String symbol;
  String priceCurrencySymbol;

  @override
  State<PriceTrendDialog> createState() => _PriceTrendDialogState();
}

class _PriceTrendDialogState extends State<PriceTrendDialog> {
  int _length = 7;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: () {
      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      return Future.value(true);
    }, child: OrientationBuilder(builder: (orientationContext, orientation) {
      final size = orientation == Orientation.portrait
          ? MediaQuery.of(context).size.width - 32
          : MediaQuery.of(context).size.width - 124;
      final sizeRatio =
          orientation == Orientation.portrait ? 336.0 / 160 : 600.0 / 231;
      return SafeArea(
          child: Center(
        child: RoundedCard(
          radius: 6,
          margin: orientation == Orientation.portrait
              ? EdgeInsets.symmetric(horizontal: 16)
              : EdgeInsets.symmetric(horizontal: 62),
          color: UI.isDarkTheme(context) ? null : Color(0xFFF5F3F1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Padding(
                            padding: EdgeInsets.only(right: 7),
                            child: Text(
                              '${widget.symbol.toUpperCase()} ${I18n.of(context).getDic(i18n_full_dic_app, 'assets')['v3.priceTrend']}（${widget.priceCurrencySymbol}）',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline4
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            )),
                        Visibility(
                            visible: orientation == Orientation.portrait,
                            child: GestureDetector(
                              onTap: () {
                                var _orientation = DeviceOrientation.portraitUp;
                                if (orientation == Orientation.portrait) {
                                  _orientation =
                                      DeviceOrientation.landscapeRight;
                                }
                                OrientationPlugin.forceOrientation(
                                    _orientation);
                              },
                              child: SvgPicture.asset(
                                "assets/images/zoom.svg",
                                width: 16,
                                color: UI.isDarkTheme(context)
                                    ? Color(0xFFFFC952)
                                    : Color(0xFF768FE1),
                              ),
                            )),
                      ]),
                      GestureDetector(
                        onTap: () {
                          OrientationPlugin.forceOrientation(
                              DeviceOrientation.portraitUp);
                          SystemChrome.setPreferredOrientations(
                              [DeviceOrientation.portraitUp]);
                          Navigator.of(context).pop();
                        },
                        child: Icon(
                          Icons.clear,
                          size: 19,
                          color: Theme.of(context).textTheme.headline4.color,
                        ),
                      )
                    ],
                  )),
              Divider(height: 1),
              Visibility(
                  visible: orientation != Orientation.portrait,
                  child: Padding(
                      padding: EdgeInsets.only(top: 9, right: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.only(
                                left: 6, right: 6, top: 5, bottom: 5),
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                                color: UI.isDarkTheme(context)
                                    ? Colors.white.withAlpha(18)
                                    : Colors.black.withAlpha(18)),
                            child: Row(
                              children: [
                                GestureDetector(
                                  child: Container(
                                    margin: EdgeInsets.only(right: 8),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(4)),
                                        color: _length == 7
                                            ? UI.isDarkTheme(context)
                                                ? Color(0xFFFFC952)
                                                : Color(0xFF768FE1)
                                            : Colors.transparent),
                                    child: Text(
                                      "7D",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: _length == 7
                                                  ? Theme.of(context)
                                                      .textTheme
                                                      .button
                                                      ?.color
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .headline1
                                                      ?.color),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _length = 7;
                                    });
                                  },
                                ),
                                GestureDetector(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(4)),
                                        color: _length == 30
                                            ? UI.isDarkTheme(context)
                                                ? Color(0xFFFFC952)
                                                : Color(0xFF768FE1)
                                            : Colors.transparent),
                                    child: Text(
                                      "1M",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: _length == 30
                                                  ? Theme.of(context)
                                                      .textTheme
                                                      .button
                                                      ?.color
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .headline1
                                                      ?.color),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _length = 30;
                                    });
                                  },
                                )
                              ],
                            ),
                          )
                        ],
                      ))),
              PriceTrendChart.withData(
                  orientation == Orientation.portrait || _length == 7
                      ? _length < widget.data.length
                          ? widget.data.sublist(0, _length)
                          : widget.data
                      : widget.data,
                  size,
                  sizeRatio,
                  UI.isDarkTheme(context),
                  orientation == Orientation.portrait
                      ? EdgeInsets.only(right: 15, top: 21)
                      : EdgeInsets.only(right: 25, top: 12))
            ],
          ),
        ),
      ));
    }));
  }
}
