// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProgressPage extends StatelessWidget {
  final Map<String, Map<String, bool>> habitTracker;

  ProgressPage({super.key, required this.habitTracker});

  // Calcular estatísticas
  Map<String, dynamic> _calculateStats() {
    int totalHabits = habitTracker.length;
    int totalPossibleCompletions = totalHabits * 7; // 7 dias na semana
    int totalCompleted = 0;
    double weeklyCompletionRate = 0.0;

    habitTracker.forEach((habit, days) {
      totalCompleted += days.values.where((isCompleted) => isCompleted).length;
    });

    if (totalPossibleCompletions > 0) {
      weeklyCompletionRate = (totalCompleted / totalPossibleCompletions) * 100;
    }

    return {
      'totalHabits': totalHabits,
      'totalCompleted': totalCompleted,
      'weeklyCompletionRate': weeklyCompletionRate,
      'totalPossible': totalPossibleCompletions,
    };
  }

  // Encontrar hábitos mais e menos realizados
  List<Map<String, dynamic>> _getHabitRanking() {
    List<Map<String, dynamic>> ranking = [];

    habitTracker.forEach((habit, days) {
      int completed = days.values.where((isCompleted) => isCompleted).length;
      double percentage = (completed / 7) * 100;
      
      ranking.add({
        'habit': habit,
        'completed': completed,
        'percentage': percentage,
      });
    });

    ranking.sort((a, b) => b['completed'].compareTo(a['completed']));
    return ranking;
  }

  // Widget para item da legenda
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final habitRanking = _getHabitRanking();

    return Scaffold(
      backgroundColor: Color(0xFFF8EBBE),
      appBar: AppBar(
        title: Text('Progresso de Hábitos'),
        backgroundColor: Color(0xFFE2AC3F),
      ),
      body: habitTracker.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum hábito para mostrar',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Adicione hábitos na página inicial para ver seu progresso',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cartão de Estatísticas
                  Card(
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '📊 Estatísticas da Semana',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A0308),
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                'Hábitos',
                                '${stats['totalHabits']}',
                                Icons.list_alt,
                                Color(0xFF7BA58D),
                              ),
                              _buildStatCard(
                                'Completos',
                                '${stats['totalCompleted']}/${stats['totalPossible']}',
                                Icons.check_circle,
                                Color(0xFFE2AC3F),
                              ),
                              _buildStatCard(
                                'Taxa',
                                '${stats['weeklyCompletionRate'].toStringAsFixed(1)}%',
                                Icons.trending_up,
                                Color(0xFF2A0308),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Gráfico de Barras - VERSÃO CORRIGIDA
                  Card(
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '📈 Progresso por Hábito',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A0308),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Dias completados na semana',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // CONTAINER DO GRÁFICO COM ALTURA AJUSTADA
                          Container(
                            height: 350, // Altura aumentada para dar mais espaço
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 7,
                                minY: 0,
                                barGroups: _createBarGroups(),
                                
                                // ESPAÇAMENTO ENTRE BARRAS PARA CABER OS RÓTULOS
                                groupsSpace: habitTracker.length > 3 ? 20 : 30,
                                
                                titlesData: FlTitlesData(
                                  show: true,
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  
                                  // TÍTULOS INFERIORES (NOMES DOS HÁBITOS) - CORRIGIDO
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (double value, TitleMeta meta) {
                                        if (value.toInt() < habitTracker.keys.length) {
                                          final habitName = habitTracker.keys.elementAt(value.toInt());
                                          
                                          // ABREVIAÇÃO MAIS AGRESSIVA PARA NOMES LONGOS
                                          String displayName;
                                          if (habitName.length > 8) {
                                            displayName = '${habitName.substring(0, 8)}...';
                                          } else {
                                            displayName = habitName;
                                          }
                                          
                                          return Padding(
                                            padding: EdgeInsets.only(top: 12), // Mais espaço acima
                                            child: Transform.rotate(
                                              angle: -45 * 3.1415927 / 180,
                                              child: Text(
                                                displayName,
                                                style: TextStyle(
                                                  fontSize: 9, // Fonte um pouco menor
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2A0308),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          );
                                        }
                                        return Text('');
                                      },
                                      reservedSize: 42, // Espaço reservado para os rótulos
                                    ),
                                  ),
                                  
                                  // TÍTULOS ESQUERDOS (NÚMEROS)
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      reservedSize: 28, // Espaço reservado para os números
                                      getTitlesWidget: (double value, TitleMeta meta) {
                                        return Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Text(
                                            value.toInt().toString(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2A0308),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Color(0xFFE2AC3F), width: 1),
                                ),
                                
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey[300],
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final habitName = habitTracker.keys.elementAt(groupIndex);
                                      final completed = rod.toY.toInt();
                                      return BarTooltipItem(
                                        '$habitName\n$completed/7 dias',
                                        TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                    tooltipMargin: 10,
                                    getTooltipColor: (group) => Color(0xFF2A0308),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // LEGENDA DO GRÁFICO
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(Color(0xFFE2AC3F), '50-79%'),
                              SizedBox(width: 16),
                              _buildLegendItem(Colors.green, '80-100%'),
                              SizedBox(width: 16),
                              _buildLegendItem(Colors.red, '0-49%'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Ranking de Hábitos
                  Card(
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏆 Ranking de Hábitos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A0308),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Ordenado por taxa de conclusão',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 16),
                          Column(
                            children: habitRanking.asMap().entries.map((entry) {
                              final index = entry.key;
                              final habit = entry.value;
                              final isTop3 = index < 3;

                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isTop3 ? Color(0xFFE2AC3F).withOpacity(0.2) : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isTop3 ? Color(0xFFE2AC3F) : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: isTop3 ? Color(0xFFE2AC3F) : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            habit['habit'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2A0308),
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: habit['percentage'] / 100,
                                            backgroundColor: Colors.grey[300],
                                            color: _getProgressColor(habit['percentage']),
                                            minHeight: 6,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      '${habit['completed']}/7',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2A0308),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '${habit['percentage'].toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A0308),
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Color(0xFFE2AC3F);
    return Colors.red;
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
              color: _getProgressColor((completedCount / 7) * 100),
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