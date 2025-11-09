import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:afn_test_admin/constants/constants.dart';

class ViewLineChart extends StatefulWidget {
  const ViewLineChart({Key? key}) : super(key: key);

  @override
  _ViewLineChartState createState() => _ViewLineChartState();
}

class _ViewLineChartState extends State<ViewLineChart> {
  List<Color> gradientColors = [
    primaryColor,
    secondaryColor,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        appPadding,
        appPadding * 1.5,
        appPadding,
        appPadding,
      ),
      child: LineChart(LineChartData(
          gridData: FlGridData(
            show: false,
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  String text = '';
                  switch (value.toInt()) {
                    case 1:
                      text = 'Sun';
                      break;
                    case 4:
                      text = 'Mon';
                      break;
                    case 7:
                      text = 'Tue';
                      break;
                    case 10:
                      text = 'Wed';
                      break;
                    case 13:
                      text = 'Thr';
                      break;
                    case 16:
                      text = 'Fri';
                      break;
                    case 19:
                      text = 'Sat';
                      break;
                  }
                  return Text(
                    text,
                    style: TextStyle(
                      color: lightTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          minX: 0,
          maxX: 20,
          maxY: 0,
          minY: 6,
          lineBarsData: [
            LineChartBarData(
                spots: [
                  FlSpot(0, 3),
                  FlSpot(4, 2),
                  FlSpot(9, 4),
                  FlSpot(12, 3),
                  FlSpot(15, 5),
                  FlSpot(18, 3),
                  FlSpot(20, 4),
                ],
                isCurved: true,

                barWidth: 5,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
               
                    
                    )
          ])),
    );
  }
}
