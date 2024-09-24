// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
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
  List<String> habits = [
    'Fazer corrida de 10km',
    'Estudar para as provas',
    'Ir para a aula de meditação',
    'Ler um livro'
  ];
  Map<String, Map<String, bool>> habitTracker = {};

  int indiceAtual = 0;

  @override
  void initState() {
    super.initState();
    for (var habit in habits) {
      habitTracker[habit] = {
        'Seg': false,
        'Ter': false,
        'Qua': false,
        'Qui': false,
        'Sex': false,
        'Sab': false,
        'Dom': false,
      };
    }
  }

  void changeWeek(String week) {
    setState(() {
      selectedWeek = week;
    });
    Navigator.pop(context);
  }

  void changeMonth(String month) {
    setState(() {
      selectedMonth = month;
    });
    Navigator.pop(context);
  }

  void toggleHabit(String habit, String day) {
    setState(() {
      habitTracker[habit]![day] = !habitTracker[habit]![day]!;
    });
  }

  void editHabit(int index) {
    TextEditingController controller = TextEditingController(text: habits[index]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Hábito'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Digite o novo hábito'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    habitTracker[controller.text] = habitTracker[habits[index]]!;
                    habitTracker.remove(habits[index]);
                    habits[index] = controller.text;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Salvar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
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
          title: Text('Adicionar Hábito'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Digite o novo hábito'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    habits.add(controller.text);
                    habitTracker[controller.text] = {
                      'Seg': false,
                      'Ter': false,
                      'Qua': false,
                      'Qui': false,
                      'Sex': false,
                      'Sab': false,
                      'Dom': false,
                    };
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Adicionar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Método para mudar a página
  void _onItemTapped(int index) {
    setState(() {
      indiceAtual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (indiceAtual == 0) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            ListTile(
              title: Text(selectedWeek, style: TextStyle(fontSize: 14)),
              trailing: Icon(Icons.arrow_drop_down),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...['1ª Semana', '2ª Semana', '3ª Semana', '4ª Semana'].map(
                            (week) => ListTile(
                              title: Text(week, style: TextStyle(fontSize: 12)),
                              onTap: () => changeWeek(week),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
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
                  'Create a life you can’t wait to wake up to',
                  style: TextStyle(fontSize: 12, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 10),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: habits.length,
                itemBuilder: (context, index) {
                  String habit = habits[index];
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
                              Text(
                                habit,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, size: 15, color: Colors.black),
                                onPressed: () => editHabit(index),
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
                                        color: habitTracker[habit]![day]!
                                            ? Color(0xFFE2AC3F)
                                            : Colors.transparent,
                                        border: Border.all(color: Color(0xFF2A0308), width: 2),
                                      ),
                                      width: 20,
                                      height: 40,
                                      child: habitTracker[habit]![day]!
                                          ? Icon(Icons.check, color: Colors.white)
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
    } else if(indiceAtual == 2){
      content = AccountPage();
    } else{
      content = ProgressPage(habitTracker: habitTracker,);
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
            label: "Home"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Progress"
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

