import 'package:app/pages/assets/asset/rewardsChart.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:intl/src/intl/date_format.dart';
import 'package:polkawallet_ui/utils/format.dart';

class PriceTrendChart extends StatelessWidget {
  final List<FlSpot> seriesList;
  final double maxY, minY;
  final DateTime maxX, minX;
  final double width;
  final double sizeRatio; //  width/height
  final bool isDark;
  static int xBase = 10;
  EdgeInsetsGeometry padding;
  Orientation orientation;
  String priceCurrencySymbol;
  PriceTrendChart(
      this.seriesList,
      this.maxX,
      this.maxY,
      this.minX,
      this.minY,
      this.width,
      this.isDark,
      this.sizeRatio,
      this.padding,
      this.orientation,
      this.priceCurrencySymbol);

  factory PriceTrendChart.withData(
      List<TimeSeriesAmount> data,
      double width,
      double sizeRatio,
      bool isDark,
      EdgeInsetsGeometry padding,
      Orientation orientation,
      String priceCurrencySymbol) {
    double maxY = 0, minY;
    DateTime maxX, minX;
    data.forEach((element) {
      if (element.amount > maxY) {
        maxY = element.amount;
      }
      if (minY == null || element.amount < minY) {
        minY = element.amount;
      }
      if (maxX == null ||
          element.time.millisecondsSinceEpoch > maxX.millisecondsSinceEpoch) {
        maxX = element.time;
      }
      if (minX == null ||
          element.time.millisecondsSinceEpoch < minX.millisecondsSinceEpoch) {
        minX = element.time;
      }
    });

    List<FlSpot> flSpotDatas = [];
    data.forEach((element) {
      flSpotDatas.add(FlSpot(
          (element.time.millisecondsSinceEpoch - minX.millisecondsSinceEpoch) /
              (maxX.millisecondsSinceEpoch - minX.millisecondsSinceEpoch) *
              xBase,
          element.amount));
    });
    return PriceTrendChart(flSpotDatas, maxX, maxY, minX, minY, width, isDark,
        sizeRatio, padding, orientation, priceCurrencySymbol);
  }

  @override
  Widget build(BuildContext context) {
    final verticalInterval = 10 /
        ((seriesList.length > 7
                ? (seriesList.length / 2 - 1)
                : (seriesList.length - 1)) +
            0.01);
    return Container(
        width: width,
        height: width / sizeRatio,
        padding: padding,
        child: Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: [
            LineChart(
              mainData(context),
              swapAnimationDuration: Duration(milliseconds: 0), // Optional
              swapAnimationCurve: Curves.linear,
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(left: 64, bottom: 26),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.filled(
                    (10 ~/ verticalInterval) + 1,
                    Container(
                      width: 2,
                      height: 8,
                      color: isDark
                          ? Color(0xFF4D4E4F)
                          : Colors.black.withAlpha(25),
                    )),
              ),
            )
          ],
        ));
  }

  LineChartData mainData(BuildContext context) {
    final _maxY = maxY * (1 + 0.15);
    final _minY = minY * (1 - 0.15);
    final horizontalInterval =
        (_maxY - _minY) / (orientation == Orientation.portrait ? 3.1 : 5.1);

    final verticalInterval = 10 /
        ((seriesList.length > 7
                ? (seriesList.length / 2 - 1)
                : (seriesList.length - 1)) +
            0.01);
    print(10 /
        ((seriesList.length > 7
                ? (seriesList.length / 2 - 1)
                : (seriesList.length - 1)) +
            0.01));
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        horizontalInterval: horizontalInterval,
        verticalInterval: verticalInterval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: isDark
                ? Colors.white.withAlpha(38)
                : Color(0xFF555555).withAlpha(38),
            strokeWidth: 1,
          );
        },
      ),
      lineTouchData: LineTouchData(
          enabled: true,
          getTouchedSpotIndicator: (data, ints) {
            return ints
                .map((e) => TouchedSpotIndicatorData(
                    FlLine(color: Colors.transparent, strokeWidth: 2),
                    FlDotData(
                      show: true,
                      getDotPainter: (p0, p1, p2, p3) {
                        return FlDotCirclePainter(
                            radius: 6,
                            color: chartLineColors()[0],
                            strokeColor: Colors.transparent);
                      },
                    )))
                .toList();
          },
          touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Color(0xFFFFFFFF).withAlpha(173),
              tooltipPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              tooltipMargin: orientation == Orientation.portrait ? -34 : -50,
              getTooltipItems: (datas) {
                return datas.map((e) {
                  var time = DateTime.fromMillisecondsSinceEpoch((e.x /
                              xBase *
                              (maxX.millisecondsSinceEpoch -
                                  minX.millisecondsSinceEpoch) +
                          minX.millisecondsSinceEpoch)
                      .toInt());
                  return LineTooltipItem("", TextStyle(),
                      textAlign: TextAlign.start,
                      children: [
                        TextSpan(
                            text: orientation == Orientation.portrait
                                ? ""
                                : "${DateFormat.Md().format(time.toLocal())}\n",
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(
                                    color: Colors.black.withAlpha(191),
                                    fontSize: UI.getTextSize(12, context),
                                    fontWeight: FontWeight.w600)),
                        TextSpan(
                            text:
                                "${Fmt.priceFloorFormatter(e.y, lengthFixed: 4)}$priceCurrencySymbol",
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(
                                    color: Colors.black.withAlpha(191),
                                    fontSize: UI.getTextSize(12, context),
                                    fontWeight: FontWeight.w600)),
                      ]);
                }).toList();
              })),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 20,
          margin: 15,
          interval: verticalInterval,
          getTextStyles: (context, index) => Theme.of(context)
              .textTheme
              .headline5
              ?.copyWith(
                  fontSize: UI.getTextSize(10, context),
                  fontWeight: FontWeight.w600,
                  height: 1.0),
          getTitles: (value) {
            var time = DateTime.fromMillisecondsSinceEpoch((value /
                        xBase *
                        (maxX.millisecondsSinceEpoch -
                            minX.millisecondsSinceEpoch) +
                    minX.millisecondsSinceEpoch)
                .toInt());
            return "${DateFormat.d().format(time.toLocal())}";
          },
        ),
        topTitles: SideTitles(showTitles: false),
        rightTitles: SideTitles(showTitles: false),
        leftTitles: SideTitles(
          showTitles: true,
          interval: horizontalInterval,
          getTextStyles: (context, index) => Theme.of(context)
              .textTheme
              .headline5
              ?.copyWith(
                  fontSize: UI.getTextSize(10, context),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .textTheme
                      .headline5
                      ?.color
                      ?.withAlpha(255 ~/ _maxY * index.toInt())),
          getTitles: (value) {
            return "${Fmt.priceFloorFormatter(value, lengthMax: 2)}$priceCurrencySymbol";
          },
          reservedSize: 55,
          margin: 10,
        ),
      ),
      borderData: FlBorderData(
          show: true,
          border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(38)
                  : Color(0xFF555555).withAlpha(38))),
      minX: 0,
      maxX: xBase * 1.0,
      minY: _minY,
      maxY: _maxY,
      lineBarsData: linesBarData(),
      backgroundColor: isDark ? Color(0xFF232323) : Colors.white,
    );
  }

  List<LineChartBarData> linesBarData() {
    final LineChartBarData lineChartBarData1 = LineChartBarData(
        spots: this.seriesList,
        isCurved: false,
        colors: chartLineColors(),
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: false,
        ),
        belowBarData: BarAreaData(
          show: true,
          gradientFrom: Offset(0, 0),
          gradientTo: Offset(0, 1),
          colors: chartBelowBarColors(),
        ));
    return [lineChartBarData1];
  }

  List<Color> chartLineColors() {
    if (isDark) {
      return [Color(0xFFFFC952)];
    } else {
      return [Color(0xFF768FE1)];
    }
  }

  List<Color> chartBelowBarColors() {
    if (isDark) {
      return [
        Color(0xFFFFC952).withOpacity(1),
        Color(0xFFFFC952).withOpacity(0)
      ];
    } else {
      return [
        Color(0xFF768FE1).withOpacity(1),
        Color(0xFF768FE1).withOpacity(0)
      ];
    }
  }
}
