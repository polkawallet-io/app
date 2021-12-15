import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RewardsChart extends StatelessWidget {
  final List<FlSpot> seriesList;
  final double maxY, minY;
  final DateTime maxX, minX;
  static int xBase = 10, yBase = 1;
  RewardsChart(this.seriesList, this.maxX, this.maxY, this.minX, this.minY);

  factory RewardsChart.withData(List<TimeSeriesAmount> data) {
    double maxY = 0, minY;
    DateTime maxX, minX;
    Map<DateTime, double> datas = Map();
    data.forEach((element) {
      var dateString = DateFormat.yMd().format(element.time.toLocal());
      if (datas[DateFormat.yMd().parse(dateString)] == null) {
        datas[DateFormat.yMd().parse(dateString)] = element.amount * yBase;
      } else {
        datas[DateFormat.yMd().parse(dateString)] =
            datas[DateFormat.yMd().parse(dateString)] + element.amount * yBase;
      }
    });
    datas.forEach((key, value) {
      if (value > maxY) {
        maxY = value;
      }
      if (minY == null || value < minY) {
        minY = value;
      }
      if (maxX == null ||
          key.millisecondsSinceEpoch > maxX.millisecondsSinceEpoch) {
        maxX = key;
      }
      if (minX == null ||
          key.millisecondsSinceEpoch < minX.millisecondsSinceEpoch) {
        minX = key;
      }
    });

    List<FlSpot> flSpotDatas = [];
    datas.forEach((key, value) {
      flSpotDatas.add(FlSpot(
          (key.millisecondsSinceEpoch - minX.millisecondsSinceEpoch) /
              (maxX.millisecondsSinceEpoch - minX.millisecondsSinceEpoch) *
              xBase,
          value));
    });
    return new RewardsChart(flSpotDatas, maxX, maxY, minX, minY);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x4DF0ECE6),
              Color(0x4DF0ECE6),
            ],
          ),
        ),
        child: LineChart(
          mainData(),
        ));
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: false,
        verticalInterval: 1.5,
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xFFE3DED8),
            strokeWidth: 0.2,
          );
        },
      ),
      lineTouchData: LineTouchData(
          enabled: false,
          getTouchedSpotIndicator: (data, ints) {
            return ints
                .map((e) => TouchedSpotIndicatorData(
                    FlLine(color: Colors.black, strokeWidth: 2),
                    FlDotData(
                      show: true,
                      getDotPainter: (p0, p1, p2, p3) {
                        return FlDotCirclePainter(
                            radius: 3, color: Colors.black);
                      },
                    )))
                .toList();
          },
          touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Color(0x50000000),
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
                        text: "${DateFormat.yMd().format(time.toLocal())}\n"),
                    TextSpan(text: "${(e.y / yBase).toStringAsFixed(6)}"),
                  ]);
                }).toList();
              })),
      titlesData: FlTitlesData(
        show: false,
      ),
      borderData: FlBorderData(
          show: false,
          border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: 0,
      maxX: xBase * 1.0,
      minY: minY * (1 - 0.15),
      maxY: maxY * (1 + 0.15),
      lineBarsData: linesBarData(),
    );
  }

  List<LineChartBarData> linesBarData() {
    final LineChartBarData lineChartBarData1 = LineChartBarData(
        spots: this.seriesList,
        isCurved: false,
        colors: [Color(0xff22BC5A)],
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: false,
          getDotPainter: (flSpot, p1, lineChartBarData, p3) {
            return FlDotCirclePainter(
                radius: 1.5, color: flSpot.y < 0 ? Colors.red : Colors.black);
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          gradientFrom: Offset(0, 0),
          gradientTo: Offset(0, 1),
          colors: [
            Color(0xFFBFFFD6).withOpacity(0.7),
            Color(0xFFBFFFD6).withOpacity(0)
          ],
        ),
        aboveBarData: BarAreaData(
          show: true,
          gradientFrom: Offset(0, 1),
          gradientTo: Offset(0, 0),
          colors: [
            Color(0xFFff0000).withOpacity(0.7),
            Color(0xFFcccc00).withOpacity(0)
          ],
        ));
    return [lineChartBarData1];
  }
}

class TimeSeriesAmount {
  final DateTime time;
  final double amount;

  TimeSeriesAmount(this.time, this.amount);
}
