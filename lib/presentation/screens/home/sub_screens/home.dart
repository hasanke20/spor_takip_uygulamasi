import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'programs/exercises/exercise.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> programs = [];
  String? nextProgramName;

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
  }

  Future<void> _fetchPrograms() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      QuerySnapshot programSnapshot = await FirebaseFirestore.instance
          .collection('Users/$uid/Programs')
          .orderBy('timestamp')
          .get();

      programs = programSnapshot.docs.map((doc) {
        return {
          'programId': doc.id,
          'programAdi': doc['programAdi'],
          'timestamp': doc['timestamp'] as Timestamp,
        };
      }).toList();

      print("Program Sayısı: ${programs.length}");
      programs.forEach((program) {
        print(
            "Program ID: ${program['programId']}, Program Adı: ${program['programAdi']}, Timestamp: ${program['timestamp']}");
      });

      // Son programı bul
      await _fetchNextProgram();
    }
  }

  Future<void> _fetchNextProgram() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    DocumentSnapshot lastProgramSnapshot = await FirebaseFirestore.instance
        .collection('Users/$uid/Values')
        .doc('LastProgram')
        .get();

    if (!lastProgramSnapshot.exists) {
      print("LastProgram belgesi bulunamadı.");
      nextProgramName = 'Program Yok';
      setState(() {});
      return;
    }

    String? lastProgramId = lastProgramSnapshot['programId'];

    int lastProgramIndex =
        programs.indexWhere((program) => program['programId'] == lastProgramId);

    if (lastProgramIndex != -1) {
      programs.sort((a, b) =>
          (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp));

      if (lastProgramIndex == programs.length - 1) {
        nextProgramName = programs[0]['programAdi'];
      } else {
        nextProgramName = programs[lastProgramIndex + 1]['programAdi'];
      }
    } else {
      nextProgramName =
          programs.isNotEmpty ? programs[0]['programAdi'] : 'Program Yok';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 250,
                height: 150,
                child: Card(
                  color: Colors.grey[800],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hemen Spor Yapmaya Başla!',
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          if (nextProgramName != null) {
                            String programId = programs.firstWhere((program) =>
                                program['programAdi'] ==
                                nextProgramName)['programId'];
                            _navigateToExerciseScreen(programId);
                          }
                        },
                        child: Text(
                          nextProgramName ?? 'Program Yok',
                          style: TextStyle(
                            color: Colors.white,
                            backgroundColor: Colors.black,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToExerciseScreen(String programId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseScreen(programId: programId),
      ),
    );
  }
}
