import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/home.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/profil.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/programs/programs.dart';

import 'sub_screens/empty.dart';
import 'sub_screens/istatistik.dart';

class Assigner extends StatefulWidget {
  Assigner({super.key});
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  State<Assigner> createState() => _AssignerState();
}

class _AssignerState extends State<Assigner> {
  int _currentTab = 2;
  final List<Widget> _screens = [
    EmptyScreen(),
    ProgramsScreen(),
    Home(),
    IstatisticScreen(),
    ProfilScreen(),
  ];
  final List<String> _screensAppBar = [
    'EmptyScreen',
    'Programlar',
    'Ana Sayfa',
    'İstatistik',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          _screensAppBar[_currentTab],
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
      body: _screens[_currentTab],
    );
  }

  Widget _buildCustomBottomNavBar() {
    return Container(
      color: Colors.black, // BottomNavigationBar arka plan rengi
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(Icons.add, 0, 'Ekle'),
          _buildNavIcon(Icons.list, 1, 'Programlar'),
          _buildNavIcon(Icons.home, 2, 'Ana Sayfa'),
          _buildNavIcon(Icons.show_chart, 3, 'İstatistik'),
          _buildNavIcon(Icons.person, 4, 'Profil'),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, String label) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.white54,
            size: 30,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.agdasima(
              textStyle: TextStyle(
                color: isSelected ? Colors.blue : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 30,
              color: Colors.blue,
            ),
        ],
      ),
    );
  }
}
