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
      }
      
      weekHabits['1ª Semana'] = [
        'Fazer corrida de 10km',
        'Estudar para as provas',
        'Ir para a aula de meditação',
        'Ler um livro'
      ];
      
      for (var habit in weekHabits['1ª Semana']!) {
        weekHabitTracker['1ª Semana']![habit] = {
          'Seg': false,
          'Ter': false,
          'Qua': false,
          'Qui': false,
          'Sex': false,
          'Sab': false,
          'Dom': false,
        };
      }
    });
  }

  void _resetForNewMonth() {
    setState(() {
      for (var week in weeks) {
        weekHabits[week] = [];
        weekHabitTracker[week] = {};
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
      
      for (var habit in weekHabits[targetWeek]!) {
        weekHabitTracker[targetWeek]![habit] = {
          'Seg': false,
          'Ter': false,
          'Qua': false,
          'Qui': false,
          'Sex': false,
          'Sab': false,
          'Dom': false,
        };
      }
    });
    _saveHabitsToFirestore();
  }

  void changeWeek(String week) {
    setState(() {
      selectedWeek = week;
    });
    _saveHabitsToFirestore();
    Navigator.pop(context);
  }

  // MÉTODO CORRIGIDO: Mudança de mês
  void changeMonth(String newMonth) {
    // Fecha o bottom sheet primeiro
    Navigator.pop(context);
    
    // Se é um mês diferente do atual, mostra confirmação
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
                  Navigator.of(context).pop(); // Fecha o dialog
                  
                  // Muda o mês e reseta
                  setState(() {
                    selectedMonth = newMonth;
                  });
                  
                  // Carrega os hábitos do novo mês (ou inicializa se não existir)
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
      // Se é o mesmo mês, só atualiza (embora isso não deva acontecer)
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
                      'Seg': false,
                      'Ter': false,
                      'Qua': false,
                      'Qui': false,
                      'Sex': false,
                      'Sab': false,
                      'Dom': false,
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
                  weekHabitTracker[selectedWeek]!.remove(currentHabits[index]);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF8EBBE),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentHabits = weekHabits[selectedWeek] ?? [];
    final previousWeeks = _getPreviousWeeks(selectedWeek);

    Widget content;
    if (indiceAtual == 0) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            ListTile(
              title: Text(selectedWeek, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: Text('${currentHabits.length} hábitos', style: TextStyle(fontSize: 10)),
              trailing: Icon(Icons.arrow_drop_down),
              onTap: _showWeekOptions,
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...['JANEIRO', 'FEVEREIRO', 'MARÇO', 'ABRIL', 'MAIO', 'JUNHO', 'JULHO', 'AGOSTO', 'SETEMBRO', 'OUTUBRO', 'NOVEMBRO', 'DEZEMBRO'].map(
                            (month) => ListTile(
                              title: Text(month, style: TextStyle(fontSize: 12)),
                              onTap: () => changeMonth(month),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Center(
                child: Text(
                  selectedMonth,
                  style: TextStyle(
                    fontSize: 33,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 1.0,
                        color: Color(0xFF2A0308),
                      ),
                    ],
                    color: Color(0xFFE2AC3F),
                  ),
                ),
              ),
            ),
            SizedBox(height: 5),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                color: Color(0xFF7BA58D),
                child: Text(
                  'Create a life you can\'t wait to wake up to',
                  style: TextStyle(fontSize: 12, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 10),
            Divider(),
            Expanded(
              child: currentHabits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_objects_outlined, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'Nenhum hábito nesta semana',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Clique no + para adicionar hábitos!',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          if (previousWeeks.isNotEmpty)
                            ElevatedButton(
                              onPressed: () {
                                _showCopyOptions(selectedWeek);
                              },
                              child: Text('Copiar de Semana Anterior'),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: currentHabits.length,
                      itemBuilder: (context, index) {
                        String habit = currentHabits[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Color(0xFF7BA58D),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        habit,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, size: 15, color: Colors.black),
                                          onPressed: () => editHabit(index),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, size: 15, color: Colors.red),
                                          onPressed: () => _deleteHabit(index),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  for (var day in ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'])
                                    Column(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            toggleHabit(habit, day);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: weekHabitTracker[selectedWeek]![habit]![day]!
                                                  ? Color(0xFFE2AC3F)
                                                  : Colors.transparent,
                                              border: Border.all(color: Color(0xFF2A0308), width: 2),
                                            ),
                                            width: 20,
                                            height: 40,
                                            child: weekHabitTracker[selectedWeek]![habit]![day]!
                                                ? Icon(Icons.check, color: Colors.white, size: 12)
                                                : null,
                                          ),
                                        ),
                                        Text(day, style: TextStyle(color: Colors.black, fontSize: 12)),
                                      ],
                                    ),
                                ],
                              ),
                            ],
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
      content = ProgressPage(habitTracker: currentWeekHabitTracker);
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8EBBE),
      body: content,
      floatingActionButton: indiceAtual == 0
          ? FloatingActionButton(
              backgroundColor: Color(0xFFE2AC3F),
              onPressed: addHabit,
              child: Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color.fromARGB(255, 226, 172, 63),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Progress",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Account",
          ),
        ],
        currentIndex: indiceAtual,
        onTap: _onItemTapped,
        selectedItemColor: Color.fromARGB(255, 42, 3, 8),
      ),
    );
  }
}