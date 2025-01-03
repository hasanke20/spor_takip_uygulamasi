import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/home.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/profil.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/programs/programs.dart';

import '../auth/login.dart';
import 'sub_screens/Istatistik/istatistik.dart';
import 'sub_screens/empty.dart';

class Assigner extends StatefulWidget {
  Assigner({super.key});
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  State<Assigner> createState() => _AssignerState();
}

class _AssignerState extends State<Assigner> {
  int _currentTab = 2; // Başlangıçta açılacak sayfa
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
    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await _showExitConfirmationDialog();
        return shouldExit;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () async {
              bool shouldExit = await _showExitConfirmationDialog();
              if (shouldExit) {
                Get.to(LoginScreen());
              }
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
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              "Çıkış Yap",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            content: Text(
              "Çıkış yapmak istediğinize emin misiniz?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  "Hayır",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  final GoogleSignIn googleSignIn = GoogleSignIn();
                  googleSignIn.signOut(); // Google oturumunu kapat
                  googleSignIn.disconnect();
                  Navigator.of(context).pop(true);
                },
                child: Text(
                  "Evet",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
            backgroundColor: Colors.black,
          ),
        )) ??
        false;
  }

  Widget _buildCustomBottomNavBar() {
    return Container(
      color: Colors.black,
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
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTab = index;
          });
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.white54,
                size: 30,
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  label,
                  style: GoogleFonts.agdasima(
                    textStyle: TextStyle(
                      color: isSelected ? Colors.blue : Colors.white54,
                      fontWeight: FontWeight.bold,
                    ),
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
        ),
      ),
    );
  }
}
