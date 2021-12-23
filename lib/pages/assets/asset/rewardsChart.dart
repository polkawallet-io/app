import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RewardsChart extends StatelessWidget {
  final List<FlSpot> seriesList;
  final double maxY, minY;
  final DateTime maxX, minX;
  final double width;
  final bool isRose;
  static int xBase = 10;
  RewardsChart(this.seriesList, this.maxX, this.maxY, this.minX, this.minY,
      this.width, this.isRose);

  factory RewardsChart.withData(List<TimeSeriesAmount> data, double width) {
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
    return RewardsChart(flSpotDatas, maxX, maxY, minX, minY, width,
        data[data.length - 1].amount - data[0].amount < 0);
  }

  @override
  Widget build(BuildContext context) {
    final chartWidth = this.width / 107 * 91;
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
            padding: EdgeInsets.only(
                right: 2.2 / 91 * chartWidth, bottom: 1 / 91.0 * chartWidth),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(5.0 / 91 * chartWidth),
                child: Container(
                    width: chartWidth,
                    height: chartWidth / 91.0 * 50,
                    child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF918F8C),
                              Color(0xFF5E5C59),
                            ],
                          ),
                        ),
                        child: LineChart(
                          mainData(),
                        ))))),
        Container(
          width: this.width,
          height: this.width / 107 * 66,
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/images/rewards_bg.png"),
                  fit: BoxFit.contain)),
        )
      ],
    );
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
      lineTouchData: LineTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: false,
      ),
      borderData: FlBorderData(show: false),
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
    if (isRose) {
      return [Color(0xff22BC5A)];
    } else {
      return [Colors.red];
    }
  }

  List<Color> chartBelowBarColors() {
    if (isRose) {
      return [
        Color(0xFFBFFFD6).withOpacity(1),
        Color(0xFFBFFFD6).withOpacity(0)
      ];
    } else {
      return [
        Color(0xFFCD4337).withOpacity(1),
        Color(0xFFCD4337).withOpacity(0)
      ];
    }
  }
}

class TimeSeriesAmount {
  final DateTime time;
  final double amount;

  TimeSeriesAmount(this.time, this.amount);
}
