import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/home.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/profile/profil.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/programs/programs.dart';

import '../auth/login.dart';
import 'sub_screens/statistics/statistics.dart';
import 'sub_screens/empty.dart';
import 'package:spor_takip_uygulamasi/logic/providers/user_data_provider.dart';

class IndexApp extends StatefulWidget {
  IndexApp({super.key});
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  State<IndexApp> createState() => _IndexAppState();
}

class _IndexAppState extends State<IndexApp> {
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
        bool shouldExit = await _showExitConfirmationDialog(context);
        return shouldExit;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () async {
              bool shouldExit = await _showExitConfirmationDialog(context);
              if (shouldExit) {
                Navigator.of(context).push(
                    CupertinoPageRoute(builder: (context) => LoginScreen()));
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

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final UserDataProvider _userDataProvider =
        Provider.of<UserDataProvider>(context, listen: false);
    return (await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text("Çıkış Yap"),
            content: Text("Çıkış yapmak istediğinize emin misiniz?"),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("Hayır"),
                isDefaultAction: true,
              ),
              CupertinoDialogAction(
                onPressed: () async {
                  await _userDataProvider.signOut();
                  Navigator.of(context).pop(true);
                },
                child: Text("Evet"),
                isDestructiveAction: true,
              ),
            ],
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
