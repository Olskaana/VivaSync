// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'account_page.dart';
import 'progress_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedWeek = '1ª Semana';
  String selectedMonth = 'SETEMBRO';
  List<String> weeks = ['1ª Semana', '2ª Semana', '3ª Semana', '4ª Semana'];
  Map<String, List<String>> weekHabits = {};
  Map<String, Map<String, Map<String, bool>>> weekHabitTracker = {};
  Map<String, Map<String, Map<String, bool>>> weekHabitGoals = {};
  int indiceAtual = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWeeks();
    _loadHabitsFromFirestore();
  }

  void _initializeWeeks() {
    for (var week in weeks) {
      weekHabits[week] = [];
      weekHabitTracker[week] = {};
      weekHabitGoals[week] = {};
    }
  }

  Future<void> _loadHabitsFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('monthly_habits')
            .doc(selectedMonth)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            for (var week in weeks) {
              weekHabits[week] = List<String>.from(data[week]?['habits'] ?? []);
              
              final trackerData = data[week]?['habitTracker'] ?? {};
              weekHabitTracker[week] = Map<String, Map<String, bool>>.from(
                trackerData.map((key, value) => 
                  MapEntry(key, Map<String, bool>.from(value))
                )
              );

              final goalsData = data[week]?['habitGoals'] ?? {};
              weekHabitGoals[week] = Map<String, Map<String, bool>>.from(
                goalsData.map((key, value) => 
                  MapEntry(key, Map<String, bool>.from(value))
                )
              );
            }
            
            selectedWeek = data['selectedWeek'] ?? '1ª Semana';
          });
        } else {
          _initializeDefaultHabits();
        }
      }
    } catch (e) {
      print('Erro ao carregar hábitos: $e');
      _initializeDefaultHabits();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeDefaultHabits() {
    setState(() {
      for (var week in weeks) {
        weekHabits[week] = [];
        weekHabitTracker[week] = {};
        weekHabitGoals[week] = {};
      }
      
      weekHabits['1ª Semana'] = [
        'Fazer corrida de 10km',
        'Estudar para as provas',
        'Ir para a aula de meditação',
        'Ler um livro'
      ];
      
      for (var habit in weekHabits['1ª Semana']!) {
        weekHabitTracker['1ª Semana']![habit] = {
          'Seg': false, 'Ter': false, 'Qua': false, 'Qui': false, 
          'Sex': false, 'Sab': false, 'Dom': false,
        };

        weekHabitGoals['1ª Semana']![habit] = {
          'Seg': false, 'Ter': false, 'Qua': false, 'Qui': false, 
          'Sex': false, 'Sab': false, 'Dom': false,
        };
      }
    });
  }

  void _resetForNewMonth() {
    setState(() {
      for (var week in weeks) {
        weekHabits[week] = [];
        weekHabitTracker[week] = {};
        weekHabitGoals[week] = {};
      }
      selectedWeek = '1ª Semana';
      
      _initializeDefaultHabits();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Novo mês iniciado! Todos os hábitos foram resetados.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveHabitsToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Map<String, dynamic> monthData = {
          'selectedWeek': selectedWeek,
          'month': selectedMonth,
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        for (var week in weeks) {
          monthData[week] = {
            'habits': weekHabits[week],
            'habitTracker': weekHabitTracker[week],
            'habitGoals': weekHabitGoals[week],
          };
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('monthly_habits')
            .doc(selectedMonth)
            .set(monthData);
        
        print('✅ Hábitos de $selectedMonth salvos!');
      }
    } catch (e) {
      print('❌ Erro ao salvar hábitos: $e');
    }
  }

  void _copyHabitsToWeek(String sourceWeek, String targetWeek) {
    setState(() {
      weekHabits[targetWeek] = List.from(weekHabits[sourceWeek]!);
      weekHabitTracker[targetWeek] = {};
      weekHabitGoals[targetWeek] = {};
      
      for (var habit in weekHabits[targetWeek]!) {
        weekHabitTracker[targetWeek]![habit] = {
          'Seg': false, 'Ter': false, 'Qua': false, 'Qui': false, 
          'Sex': false, 'Sab': false, 'Dom': false,
        };

        if (weekHabitGoals[sourceWeek]!.containsKey(habit)) {
          weekHabitGoals[targetWeek]![habit] = Map.from(weekHabitGoals[sourceWeek]![habit]!);
        } else {
          weekHabitGoals[targetWeek]![habit] = {
            'Seg': false, 'Ter': false, 'Qua': false, 'Qui': false, 
            'Sex': false, 'Sab': false, 'Dom': false,
          };
        }
      }
    });
    _saveHabitsToFirestore();
  }

  void _setHabitGoal(String habit) {
    final currentGoals = weekHabitGoals[selectedWeek]![habit] ?? {
      'Seg': false, 'Ter': false, 'Qua': false, 'Qui': false, 
      'Sex': false, 'Sab': false, 'Dom': false,
    };

    Map<String, bool> selectedDays = Map.from(currentGoals);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF8EBBE), Color(0xFFE2AC3F).withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFE2AC3F).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.flag, color: Color(0xFFE2AC3F), size: 24),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Definir Meta',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A0308),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF7BA58D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF7BA58D).withOpacity(0.3)),
                      ),
                      child: Text(
                        habit,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2A0308),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    Text(
                      'Selecione os dias da semana:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2A0308),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var day in ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'])
                          AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            child: ChoiceChip(
                              label: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: selectedDays[day]! ? Colors.white : Color(0xFF2A0308),
                                ),
                              ),
                              selected: selectedDays[day]!,
                              onSelected: (bool selected) {
                                setDialogState(() {
                                  selectedDays[day] = selected;
                                });
                              },
                              selectedColor: Color(0xFFE2AC3F),
                              backgroundColor: Colors.grey[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Color(0xFFE2AC3F)),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Color(0xFFE2AC3F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                weekHabitGoals[selectedWeek]![habit] = selectedDays;
                              });
                              _saveHabitsToFirestore();
                              Navigator.of(context).pop();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Meta definida para $habit'),
                                    ],
                                  ),
                                  backgroundColor: Color(0xFF7BA58D),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFE2AC3F),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Salvar Meta',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void changeWeek(String week) {
    setState(() {
      selectedWeek = week;
    });
    _saveHabitsToFirestore();
    Navigator.pop(context);
  }

  void changeMonth(String newMonth) {
    Navigator.pop(context);
    
    if (newMonth != selectedMonth) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Iniciar Novo Mês'),
            content: Text('Deseja iniciar o mês de $newMonth?\n\n'
                         '📅 Todos os hábitos e progresso serão resetados para começar um novo ciclo.'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  
                  setState(() {
                    selectedMonth = newMonth;
                  });
                  
                  await _loadHabitsFromFirestore();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Agora você está no mês de $newMonth!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text('Sim, Iniciar Novo Mês', style: TextStyle(color: Colors.green)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancelar'),
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        selectedMonth = newMonth;
      });
      _saveHabitsToFirestore();
    }
  }

  void toggleHabit(String habit, String day) {
    setState(() {
      weekHabitTracker[selectedWeek]![habit]![day] = 
          !weekHabitTracker[selectedWeek]![habit]![day]!;
    });
    _saveHabitsToFirestore();
  }

  void editHabit(int index) {
    final currentHabits = weekHabits[selectedWeek]!;
    TextEditingController controller = TextEditingController(text: currentHabits[index]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Hábito - $selectedWeek'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Digite o novo hábito'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    final oldHabit = currentHabits[index];
                    weekHabitTracker[selectedWeek]![controller.text] = 
                        weekHabitTracker[selectedWeek]![oldHabit]!;
                    weekHabitTracker[selectedWeek]!.remove(oldHabit);
                    
                    weekHabitGoals[selectedWeek]![controller.text] = 
                        weekHabitGoals[selectedWeek]![oldHabit] ?? {
                          'Seg': false, 'Ter': false, 'Qua': false, 'Qui': false, 
                          'Sex': false, 'Sab': false, 'Dom': false,
                        };
                    weekHabitGoals[selectedWeek]!.remove(oldHabit);
                    
                    currentHabits[index] = controller.text;
                  });
                  _saveHabitsToFirestore();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Salvar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void addHabit() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adicionar Hábito - $selectedWeek'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Digite o novo hábito'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    weekHabits[selectedWeek]!.add(controller.text);
                    weekHabitTracker[selectedWeek]![controller.text] = {
                      'Seg': false, 'Ter': false, 'Qua': false, 'Qui': false, 
                      'Sex': false, 'Sab': false, 'Dom': false,
                    };
                    
                    weekHabitGoals[selectedWeek]![controller.text] = {
                      'Seg': false, 'Ter': false, 'Qua': false, 'Qui': false, 
                      'Sex': false, 'Sab': false, 'Dom': false,
                    };
                  });
                  _saveHabitsToFirestore();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Adicionar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _deleteHabit(int index) {
    final currentHabits = weekHabits[selectedWeek]!;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Deletar Hábito'),
          content: Text('Tem certeza que deseja deletar "${currentHabits[index]}" da $selectedWeek?'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  final habitToDelete = currentHabits[index];
                  weekHabitTracker[selectedWeek]!.remove(habitToDelete);
                  weekHabitGoals[selectedWeek]!.remove(habitToDelete);
                  currentHabits.removeAt(index);
                });
                _saveHabitsToFirestore();
                Navigator.of(context).pop();
              },
              child: Text('Deletar', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _showCopyOptions(String targetWeek) {
    final previousWeeks = _getPreviousWeeks(targetWeek);
    
    if (previousWeeks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não há semanas anteriores para copiar')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Copiar hábitos para $targetWeek',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              for (var sourceWeek in previousWeeks)
                Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Copiar da $sourceWeek'),
                      subtitle: Text('${weekHabits[sourceWeek]?.length ?? 0} hábitos'),
                      onTap: () {
                        Navigator.pop(context);
                        _showCopyConfirmation(sourceWeek, targetWeek);
                      },
                    ),
                    if (sourceWeek != previousWeeks.last) Divider(height: 1),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  List<String> _getPreviousWeeks(String targetWeek) {
    final targetIndex = weeks.indexOf(targetWeek);
    if (targetIndex <= 0) return [];
    
    return weeks.sublist(0, targetIndex).where((week) => weekHabits[week]!.isNotEmpty).toList();
  }

  void _showCopyConfirmation(String sourceWeek, String targetWeek) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Copiar Hábitos'),
          content: Text('Deseja copiar os ${weekHabits[sourceWeek]!.length} hábitos da $sourceWeek para a $targetWeek? '
                       'Isso irá substituir os hábitos atuais da $targetWeek.'),
          actions: [
            TextButton(
              onPressed: () {
                _copyHabitsToWeek(sourceWeek, targetWeek);
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Hábitos copiados da $sourceWeek para $targetWeek!')),
                );
              },
              child: Text('Copiar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _showWeekOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var week in weeks)
                Column(
                  children: [
                    ListTile(
                      title: Text(week, style: TextStyle(fontSize: 16)),
                      subtitle: Text('${weekHabits[week]?.length ?? 0} hábitos', style: TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (week != '1ª Semana' && _getPreviousWeeks(week).isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.copy, size: 18),
                              onPressed: () {
                                _showCopyOptions(week);
                                Navigator.pop(context);
                              },
                              tooltip: 'Copiar de semanas anteriores',
                            ),
                          if (week == selectedWeek)
                            Icon(Icons.check, color: Colors.green),
                        ],
                      ),
                      onTap: () => changeWeek(week),
                    ),
                    if (week != weeks.last) Divider(height: 1),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      indiceAtual = index;
    });
  }

  Map<String, Map<String, bool>> get currentWeekHabitTracker {
    return weekHabitTracker[selectedWeek] ?? {};
  }
  
  Map<String, Map<String, bool>> get currentWeekHabitGoals {
    return weekHabitGoals[selectedWeek] ?? {};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF8EBBE),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFE2AC3F),
              ),
              SizedBox(height: 16),
              Text(
                'Carregando seus hábitos...',
                style: TextStyle(
                  color: Color(0xFF2A0308),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentHabits = weekHabits[selectedWeek] ?? [];
    final previousWeeks = _getPreviousWeeks(selectedWeek);

    Widget content;
    if (indiceAtual == 0) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            
            // HEADER ELEGANTE
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE2AC3F).withOpacity(0.1), Color(0xFF7BA58D).withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  // SEMANA SELECIONADA
                  GestureDetector(
                    onTap: _showWeekOptions,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedWeek,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2A0308),
                                ),
                              ),
                              Text(
                                '${currentHabits.length} hábitos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.arrow_drop_down, color: Color(0xFFE2AC3F)),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // MÊS
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (BuildContext context) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Selecionar Mês',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2A0308),
                                      ),
                                    ),
                                  ),
                                  ...['JANEIRO', 'FEVEREIRO', 'MARÇO', 'ABRIL', 'MAIO', 'JUNHO', 
                                      'JULHO', 'AGOSTO', 'SETEMBRO', 'OUTUBRO', 'NOVEMBRO', 'DEZEMBRO'].map(
                                    (month) => ListTile(
                                      title: Text(
                                        month,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: month == selectedMonth ? Color(0xFFE2AC3F) : Color(0xFF2A0308),
                                          fontWeight: month == selectedMonth ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      trailing: month == selectedMonth 
                                          ? Icon(Icons.check, color: Color(0xFFE2AC3F), size: 20)
                                          : null,
                                      onTap: () => changeMonth(month),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Text(
                      selectedMonth,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE2AC3F),
                        shadows: [
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 2.0,
                            color: Color(0xFF2A0308).withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // FRASE INSPIRADORA
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFF7BA58D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Create a life you can\'t wait to wake up to',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // LISTA DE HÁBITOS
            Expanded(
              child: currentHabits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_objects_outlined, size: 60, color: Color(0xFFE2AC3F)),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum hábito nesta semana',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF2A0308),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Toque no + para começar!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 20),
                          if (previousWeeks.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () => _showCopyOptions(selectedWeek),
                              icon: Icon(Icons.copy, size: 16),
                              label: Text('Copiar de Semana Anterior'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF7BA58D),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: currentHabits.length,
                      itemBuilder: (context, index) {
                        String habit = currentHabits[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          child: Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF7BA58D).withOpacity(0.1),
                                    Color(0xFFE2AC3F).withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // CABEÇALHO DO HÁBITO
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF7BA58D).withOpacity(0.8),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            habit,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            // BOTÃO DE META (COM MAIS ESPAÇAMENTO)
                                            IconButton(
                                              icon: Container(
                                                padding: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  '🔥',
                                                  style: TextStyle(fontSize: 14),
                                                ),
                                              ),
                                              onPressed: () => _setHabitGoal(habit),
                                              tooltip: 'Definir meta',
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                            ),
                                            SizedBox(width: 12), // MAIS ESPAÇAMENTO
                                            // BOTÃO EDITAR
                                            IconButton(
                                              icon: Icon(Icons.edit, size: 18, color: Colors.white),
                                              onPressed: () => editHabit(index),
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                            ),
                                            SizedBox(width: 12), // MAIS ESPAÇAMENTO
                                            // BOTÃO DELETAR
                                            IconButton(
                                              icon: Icon(Icons.delete, size: 18, color: Colors.white),
                                              onPressed: () => _deleteHabit(index),
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // DIAS DA SEMANA
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        for (var day in ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'])
                                          Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () => toggleHabit(habit, day),
                                                child: AnimatedContainer(
                                                  duration: Duration(milliseconds: 200),
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: weekHabitTracker[selectedWeek]![habit]![day]!
                                                        ? Color(0xFFE2AC3F)
                                                        : Colors.transparent,
                                                    border: Border.all(
                                                      color: weekHabitTracker[selectedWeek]![habit]![day]!
                                                          ? Color(0xFFE2AC3F)
                                                          : Color(0xFF2A0308).withOpacity(0.3),
                                                      width: 2,
                                                    ),
                                                    boxShadow: weekHabitTracker[selectedWeek]![habit]![day]!
                                                        ? [
                                                            BoxShadow(
                                                              color: Color(0xFFE2AC3F).withOpacity(0.3),
                                                              blurRadius: 4,
                                                              offset: Offset(0, 2),
                                                            )
                                                          ]
                                                        : [],
                                                  ),
                                                  child: weekHabitTracker[selectedWeek]![habit]![day]!
                                                      ? Icon(Icons.check, color: Colors.white, size: 16)
                                                      : null,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                day,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF2A0308),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    } else if (indiceAtual == 2) {
      content = AccountPage();
    } else {
      content = ProgressPage(
        habitTracker: currentWeekHabitTracker,
        habitGoals: currentWeekHabitGoals,
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8EBBE),
      body: content,
      floatingActionButton: indiceAtual == 0
          ? FloatingActionButton(
              backgroundColor: Color(0xFFE2AC3F),
              onPressed: addHabit,
              child: Icon(Icons.add, color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            backgroundColor: Color(0xFFE2AC3F),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: "Progress",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outlined),
                activeIcon: Icon(Icons.person),
                label: "Account",
              ),
            ],
            currentIndex: indiceAtual,
            onTap: _onItemTapped,
            selectedItemColor: Color(0xFF2A0308),
            unselectedItemColor: Color(0xFF2A0308).withOpacity(0.6),
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}