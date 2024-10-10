import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:spor_takip_uygulamasi/presentation/home.dart';
import 'package:spor_takip_uygulamasi/presentation/profil.dart';
import 'package:spor_takip_uygulamasi/presentation/program.dart';

import 'empty.dart';
import 'istatistik.dart';

class Assigner extends StatefulWidget {
  const Assigner({super.key});

  @override
  State<Assigner> createState() => _AssignerState();
}

class _AssignerState extends State<Assigner> {
  int _currentTab = 0;
  final List<Widget> _screens = [
    Home(),
    EmptyScreen(),
    ProgramScreen(),
    IstatisticScreen(),
    ProfilScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
