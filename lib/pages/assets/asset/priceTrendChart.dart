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
  PriceTrendChart(this.seriesList, this.maxX, this.maxY, this.minX, this.minY,
      this.width, this.isDark, this.sizeRatio, this.padding);

  factory PriceTrendChart.withData(List<TimeSeriesAmount> data, double width,
      double sizeRatio, bool isDark, EdgeInsetsGeometry padding) {
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
    return PriceTrendChart(
        flSpotDatas, maxX, maxY, minX, minY, width, isDark, sizeRatio, padding);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width / sizeRatio,
      padding: padding,
      child: Stack(
        children: [
          // ClipRRect(
          //     borderRadius: BorderRadius.all(Radius.circular(4)),
          //     child: Stack(
          //       children: [
          //         LineChart(
          //           LineChartData(
          //             gridData: FlGridData(
          //               show: true,
          //               drawVerticalLine: false,
          //               drawHorizontalLine: true,
          //               verticalInterval: 1.5,
          //               getDrawingHorizontalLine: (value) {
          //                 return FlLine(
          //                   color: Theme.of(context).dividerColor,
          //                   strokeWidth: 0.2,
          //                 );
          //               },
          //             ),
          //             titlesData: FlTitlesData(
          //               show: false,
          //             ),
          //             borderData: FlBorderData(show: false),
          //             minX: 0,
          //             maxX: xBase * 1.0,
          //             minY: minY * (1 - 0.15),
          //             maxY: maxY * (1 + 0.15),
          //             lineBarsData: linesBarData(),
          //             backgroundColor:
          //                 isDark ? Color(0xFF232323) : Colors.white,
          //           ),
          //         ),
          //         Container(
          //           decoration:
          //               BoxDecoration(color: Colors.transparent, boxShadow: [
          //             BoxShadow(
          //                 blurStyle: BlurStyle.inner,
          //                 blurRadius: 2,
          //                 spreadRadius: 1,
          //                 offset: Offset(0, 0),
          //                 color: Colors.black.withAlpha(77))
          //           ]),
          //           width: double.infinity,
          //           height: double.infinity,
          //         )
          //       ],
          //     )),
          LineChart(
            mainData(context),
          )
        ],
      ),
    );
  }

  LineChartData mainData(BuildContext context) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        verticalInterval: 1.5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Theme.of(context).dividerColor,
            strokeWidth: 0.2,
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
              tooltipBgColor: Color(0x70000000),
              getTooltipItems: (datas) {
                return datas.map((e) {
                  var time = DateTime.fromMillisecondsSinceEpoch((e.x /
                              xBase *
                              (maxX.millisecondsSinceEpoch -
                                  minX.millisecondsSinceEpoch) +
                          minX.millisecondsSinceEpoch)
                      .toInt());
                  return LineTooltipItem("", TextStyle(), children: [
                    TextSpan(
                        text: "${DateFormat.yMd().format(time.toLocal())}\n",
                        style: Theme.of(context).textTheme.headline5?.copyWith(
                            color: Colors.white,
                            fontSize: UI.getTextSize(10, context),
                            fontWeight: FontWeight.w600)),
                    TextSpan(
                        text: "${Fmt.priceFloorFormatter(e.y, lengthFixed: 4)}",
                        style: Theme.of(context).textTheme.headline5?.copyWith(
                            color: Colors.white,
                            fontSize: UI.getTextSize(10, context),
                            fontWeight: FontWeight.w600)),
                  ]);
                }).toList();
              })),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: 10 /
              ((seriesList.length > 7
                      ? (seriesList.length / 2 - 1)
                      : (seriesList.length - 1)) +
                  0.01),
          getTextStyles: (context, index) => Theme.of(context)
              .textTheme
              .headline5
              ?.copyWith(
                  fontSize: UI.getTextSize(10, context),
                  fontWeight: FontWeight.w600),
          getTitles: (value) {
            var time = DateTime.fromMillisecondsSinceEpoch((value /
                        xBase *
                        (maxX.millisecondsSinceEpoch -
                            minX.millisecondsSinceEpoch) +
                    minX.millisecondsSinceEpoch)
                .toInt());
            return "${DateFormat.d().format(time.toLocal())}";
          },
          margin: 8,
        ),
        topTitles: SideTitles(showTitles: false),
        rightTitles: SideTitles(showTitles: false),
        leftTitles: SideTitles(
          showTitles: true,
          getTextStyles: (context, index) => Theme.of(context)
              .textTheme
              .headline5
              ?.copyWith(
                  fontSize: UI.getTextSize(10, context),
                  fontWeight: FontWeight.w600),
          getTitles: (value) {
            return Fmt.priceFloorFormatter(value, lengthMax: 2);
          },
          reservedSize: 50,
          margin: 10,
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: xBase * 1.0,
      minY: minY * (1 - 0.15),
      maxY: maxY * (1 + 0.15),
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
