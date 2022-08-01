import 'package:app/pages/assets/asset/priceTrendChart.dart';
import 'package:app/pages/assets/asset/rewardsChart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:orientation/orientation.dart';
import 'package:polkawallet_ui/utils/index.dart';

class PriceTrendDialog extends StatefulWidget {
  PriceTrendDialog(this.data, this.symbol, {Key key}) : super(key: key);
  List<TimeSeriesAmount> data;
  String symbol;

  @override
  State<PriceTrendDialog> createState() => _PriceTrendDialogState();
}

class _PriceTrendDialogState extends State<PriceTrendDialog> {
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
                      Text(
                        '${widget.symbol.toUpperCase()} Price Trend \$',
                        style: Theme.of(context)
                            .textTheme
                            .headline4
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              var _orientation = DeviceOrientation.portraitUp;
                              if (orientation == Orientation.portrait) {
                                _orientation = DeviceOrientation.landscapeRight;
                              }
                              OrientationPlugin.forceOrientation(_orientation);
                            },
                            child: Icon(
                              Icons.ac_unit,
                              size: 19,
                              color:
                                  Theme.of(context).textTheme.headline4.color,
                            ),
                          ),
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
                              color:
                                  Theme.of(context).textTheme.headline4.color,
                            ),
                          )
                        ],
                      )
                    ],
                  )),
              Divider(height: 1),
              PriceTrendChart.withData(
                  widget.data, size, sizeRatio, UI.isDarkTheme(context))
            ],
          ),
        ),
      ));
    }));
  }
}
