import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spor_takip_uygulamasi/repository/addToFirebase.dart';
import 'package:provider/provider.dart';
import '../../../../logic/providers/user_data_provider.dart';

import 'programs/exercises/exercise.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<void> _fetchProgramsFuture;
  List<Map<String, dynamic>> programs = [];
  String? nextProgramName;
  String? lastProgramName;

  @override
  void initState() {
    super.initState();
    _fetchProgramsFuture = Provider.of<UserDataProvider>(context, listen: false)
        .fetchPrograms(
            context, programs, lastProgramName ?? '', nextProgramName ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Center(
          child: FutureBuilder<void>(
            future: _fetchProgramsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(); // Show loading indicator
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}'); // Handle error
              }
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgramInfoCard(),
                    SizedBox(height: 10),
                    _buildWeightButton(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgramInfoCard() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height / 5,
      decoration: BoxDecoration(
        color: CupertinoColors.darkBackgroundGray,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Hemen Spor Yapmaya Başla!',
            style: TextStyle(
              fontSize: 28,
              color: CupertinoColors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          Text(
            'Son yapılan program: $lastProgramName',
            style: TextStyle(
              color: CupertinoColors.white.withOpacity(0.7),
              fontSize: 20,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sıradaki Program:',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 20,
                ),
              ),
              SizedBox(width: 10),
              CupertinoButton(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(15),
                onPressed: () {
                  if (nextProgramName != null) {
                    String programId = programs.firstWhere((program) =>
                        program['programAdi'] == nextProgramName)['programId'];
                    _navigateToExerciseScreen(programId);
                  }
                },
                child: Text(
                  nextProgramName ?? 'Program Yok',
                  style: TextStyle(
                    fontSize: 18,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightButton() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.darkBackgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      height: MediaQuery.of(context).size.height / 10,
      width: MediaQuery.of(context).size.width / 2,
      child: CupertinoButton(
        onPressed: showWeightDialog,
        child: Text(
          'Kilonu Gir',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 35,
          ),
        ),
      ),
    );
  }

  void _navigateToExerciseScreen(String programId) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ExerciseScreen(programId: programId),
      ),
    );
  }

  void showWeightDialog() {
    final TextEditingController weightController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Tartı Girişi'),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CupertinoTextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              placeholder: 'Kilo (kg)',
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                double? weight = double.tryParse(weightController.text);
                if (weight != null) {
                  final userDataProvider = context.read<UserDataProvider>();
                  bool success = await userDataProvider.addWeight(weight);
                  if (success) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
}
