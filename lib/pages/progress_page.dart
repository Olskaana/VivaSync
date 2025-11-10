// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProgressPage extends StatelessWidget {
  final Map<String, Map<String, bool>> habitTracker;
  final Map<String, Map<String, bool>> habitGoals;

  const ProgressPage({
    super.key, 
    required this.habitTracker,
    required this.habitGoals,
  });

  // Calcular estatísticas
  Map<String, dynamic> _calculateStats() {
    int totalHabits = habitTracker.length;
    int totalCompleted = 0;
    int totalGoalDays = 0;

    habitTracker.forEach((habit, days) {
      totalCompleted += days.values.where((isCompleted) => isCompleted).length;
      
      // Calcular dias de meta
      final goalDays = habitGoals[habit] ?? {};
      totalGoalDays += goalDays.values.where((isGoal) => isGoal).length;
    });

    double completionRate = totalGoalDays > 0 ? (totalCompleted / totalGoalDays) * 100 : 0.0;

    return {
      'totalHabits': totalHabits,
      'totalCompleted': totalCompleted,
      'totalGoalDays': totalGoalDays,
      'completionRate': completionRate,
    };
  }

  // Encontrar hábitos mais e menos realizados
  List<Map<String, dynamic>> _getHabitRanking() {
    List<Map<String, dynamic>> ranking = [];

    habitTracker.forEach((habit, days) {
      int completed = days.values.where((isCompleted) => isCompleted).length;
      final goalDays = habitGoals[habit] ?? {};
      int goalCount = goalDays.values.where((isGoal) => isGoal).length;
      
      double percentage = goalCount > 0 ? (completed / goalCount) * 100 : 0.0;
      
      ranking.add({
        'habit': habit,
        'completed': completed,
        'goal': goalCount,
        'percentage': percentage,
      });
    });

    ranking.sort((a, b) => b['percentage'].compareTo(a['percentage']));
    return ranking;
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
                                'Realizado',
                                '${stats['totalCompleted']}/${stats['totalGoalDays']}',
                                Icons.check_circle,
                                Color(0xFFE2AC3F),
                              ),
                              _buildStatCard(
                                'Atingido',
                                '${stats['completionRate'].toStringAsFixed(1)}%',
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

                  // GRÁFICO HORIZONTAL - Meta vs Realizado (SEM ROLAGEM)
                  Card(
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '📊 Meta vs Realizado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A0308),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Comparação entre dias planejados e realizados',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // GRÁFICO DE BARRAS HORIZONTAIS - TODOS OS HÁBITOS VISÍVEIS
                          _buildHorizontalBarChart(),
                          
                          // LEGENDA
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(Color(0xFF7BA58D), 'Meta'),
                              SizedBox(width: 20),
                              _buildLegendItem(Color(0xFFE2AC3F), 'Realizado'),
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
                            '🏆 Desempenho dos Hábitos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A0308),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Ordenado por % de meta atingida',
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
                                          SizedBox(height: 4),
                                          Text(
                                            '${habit['completed']}/${habit['goal']} dias (${habit['percentage'].toStringAsFixed(0)}%)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
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

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Color(0xFFE2AC3F);
    return Colors.red;
  }

  Widget _buildHorizontalBarChart() {
    final habits = habitTracker.keys.toList();
    
    return Column(
      children: habits.map((habit) {
        final completed = habitTracker[habit]!.values.where((isCompleted) => isCompleted).length;
        final goal = habitGoals[habit]?.values.where((isGoal) => isGoal).length ?? 0;
        final maxDays = completed > goal ? completed : goal;
        
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome do hábito
              Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  habit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A0308),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Barras de progresso
              Row(
                children: [
                  // Barra da META
                  Expanded(
                    flex: goal > 0 ? goal : 0,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(0xFF7BA58D),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(4),
                          right: goal > 0 && completed > 0 ? Radius.zero : Radius.circular(4),
                        ),
                      ),
                      child: goal > 0 ? Center(
                        child: Text(
                          '$goal',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ) : SizedBox(),
                    ),
                  ),
                  
                  // Barra do REALIZADO
                  Expanded(
                    flex: completed > 0 ? completed : 0,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(0xFFE2AC3F),
                        borderRadius: BorderRadius.horizontal(
                          left: goal > 0 && completed > 0 ? Radius.zero : Radius.circular(4),
                          right: Radius.circular(4),
                        ),
                      ),
                      child: completed > 0 ? Center(
                        child: Text(
                          '$completed',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ) : SizedBox(),
                    ),
                  ),
                  
                  // Espaço vazio se necessário (máximo 7 dias)
                  if (maxDays < 7)
                    Expanded(
                      flex: 7 - maxDays,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Labels abaixo das barras
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Meta: $goal dias',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Realizado: $completed dias',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}