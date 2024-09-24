// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? selectedGender; // Para armazenar o gênero selecionado
  final List<String> genderOptions = ['Feminino', 'Masculino', 'Prefiro não comentar'];

  void _showGenderOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: genderOptions.map((String gender) {
            return ListTile(
              title: Text(gender),
              onTap: () {
                setState(() {
                  selectedGender = gender;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                radius: 100,
                backgroundImage: NetworkImage('https://via.placeholder.com/150'),
              ),
            ),
            SizedBox(height: 60),
            Text(
              'Juliana Weika',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            Text(
              'juliana.weika@gmail.com',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 30),
            Text(
              'Idade: 40',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 30),
            // Gênero: Botão único que mostra as opções em um modal
            OutlinedButton(
              onPressed: _showGenderOptions,
              child: Text(
                'Gênero: ${selectedGender ?? "Não selecionado"}',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
