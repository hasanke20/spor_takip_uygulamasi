import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/home.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/profil.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/programs.dart';

import 'sub_screens/empty.dart';
import 'sub_screens/istatistik.dart';

class Assigner extends StatefulWidget {
  Assigner({super.key});
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  State<Assigner> createState() => _AssignerState();
}

class _AssignerState extends State<Assigner> {
  int _currentTab = 0;
  final List<Widget> _screens = [
    Home(),
    EmptyScreen(),
    ProgramsScreen(),
    IstatisticScreen(),
    ProfilScreen()
  ];
  final List<String> _screensAppBar = [
    'Home',
    'EmptyScreen',
    'Programlar',
    'IstatisticScreen',
    'ProfilScreen'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screensAppBar[_currentTab]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentTab = 0;
          });
        },
        child: Icon(Icons.home),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        gapLocation: GapLocation.center,
        icons: [Icons.add, Icons.list, Icons.show_chart, Icons.person],
        activeIndex: _currentTab,
        onTap: (int index) {
          setState(
            () {
              _currentTab = index + 1;
            },
          );
        },
      ),
      body: _screens[_currentTab],
    );
  }
}
