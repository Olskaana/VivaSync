// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProgressPage extends StatelessWidget {
  final Map<String, Map<String, bool>> habitTracker;

  ProgressPage({super.key, required this.habitTracker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Progresso de Hábitos'),
        backgroundColor: Color(0xFFE2AC3F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Gráfico de Progresso Semanal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 7,
                  barGroups: _createBarGroups(),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final habitName = habitTracker.keys.elementAt(value.toInt());
                          return Transform.rotate(
                            angle: -45 * 3.1415927 / 180,
                            child: Text(habitName, style: TextStyle(fontSize: 8,
                            fontWeight: FontWeight.bold,                           
                            ),),
                          );
                        },
                      )
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(value.toInt().toString());
                        },
                      )
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups() {
    List<BarChartGroupData> barGroups = [];
    int habitIndex = 0;

    habitTracker.forEach((habit, days) {
      int completedCount = days.values.where((isCompleted) => isCompleted).length;

      barGroups.add(
        BarChartGroupData(
          x: habitIndex,
          barRods: [
            BarChartRodData(
              toY: completedCount.toDouble(),
              color: const Color(0xFFE2AC3F),
              width: 20,
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        ),
      );

      habitIndex++;
    });

    return barGroups;
  }
}
