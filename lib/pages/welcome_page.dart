// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';


class WelcomePage extends StatelessWidget {
   WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(248, 235, 190, 1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
             Image.asset("images/Logo.png",
             height: 250,
             width: 250,
             ),
             SizedBox(height: 50),
             Text(
              "Welcome to VivaSync",
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(226, 172, 63, 1),
              ),
            ),
             SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(226, 172, 63, 1),
                fixedSize:  Size(250, 50),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child:  Text('Login', style: TextStyle(color: Colors.black)),
            ),
             SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(226, 172, 63, 1),
                fixedSize:  Size(250, 50),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child:  Text('Register', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
