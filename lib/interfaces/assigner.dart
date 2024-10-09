import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:spor_takip_uygulamasi/interfaces/home.dart';
import 'package:spor_takip_uygulamasi/interfaces/profil.dart';
import 'package:spor_takip_uygulamasi/interfaces/program.dart';
import 'package:spor_takip_uygulamasi/interfaces/uyegirisi.dart';

class Assigner extends StatefulWidget {
  const Assigner({super.key});

  @override
  State<Assigner> createState() => _AssignerState();
}

class _AssignerState extends State<Assigner> {
  int _currentTab = 0;

  void _toAnaSayfa() {
    setState(() {
      _currentTab = 1; // Ana sayfa için indexi 1 olarak ayarla
    });
  }

  final List<Widget> _screens = [
    UyeGirisi(),
    Home(),
    ProgramScreen(),
    ProfilScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentTab = 1;
          });
        },
        child: Icon(Icons.home),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        gapLocation: GapLocation.center,
        icons: [Icons.list, Icons.person],
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
