import 'package:bcard3/screens/BusinessCardHome.dart';
import 'package:flutter/material.dart';
import 'package:bcard3/screens/contactslist.dart';

class CardHome extends StatefulWidget {
  const CardHome({super.key});
  static String id = 'card_home';
  @override
  State<CardHome> createState() => _CardHomeState();
}

class _CardHomeState extends State<CardHome> {
  int myIndex = 0;
  List<Widget> widgetList = [
    BusinessCardUI(),
    ContactsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: widgetList[myIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          setState(() {
            myIndex = index;
          });
        },
        currentIndex: myIndex,
        selectedItemColor: Color(0xff004aad),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Cartões'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Definições'),
        ],
      ),
    );
  }
}


