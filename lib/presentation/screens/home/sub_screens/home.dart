import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spor_takip_uygulamasi/repository/addToFirebase.dart';

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
    _fetchProgramsFuture = _fetchPrograms();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: FutureBuilder<void>(
            future: _fetchProgramsFuture,
            builder: (context, snapshot) {
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
        color: Colors.grey[900], // Koyu gri arka plan
        borderRadius: BorderRadius.circular(20), // Daha yuvarlak köşeler
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
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
              fontSize: 28, // Daha büyük başlık
              color: Colors.white, // Beyaz metin rengi
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          Text(
            'Son yapılan program: $lastProgramName',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 20, // Orta boyut
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sıradaki Program:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  if (nextProgramName != null) {
                    String programId = programs.firstWhere((program) =>
                        program['programAdi'] == nextProgramName)['programId'];
                    _navigateToExerciseScreen(programId);
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  nextProgramName ?? 'Program Yok',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
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
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      height: MediaQuery.of(context).size.height / 10,
      width: MediaQuery.of(context).size.width / 2,
      child: TextButton(
        onPressed: showWeightDialog,
        child: Text(
          'Kilonu Gir',
          style: TextStyle(color: Colors.white, fontSize: 35),
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

  void showWeightDialog() {
    final TextEditingController weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text('Tartı Girişi', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Kilo (kg)',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('İptal', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                double? weight = double.tryParse(weightController.text);
                if (weight != null) {
                  bool success = await AddWeight.addWeight(context, weight);
                  if (success) {
                    Navigator.of(context).pop();
                  } else {
                    // Hata durumu, ekranı kapatmadan bildirim göster
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Kilo eklenirken bir hata oluştu.'),
                      backgroundColor: Colors.red,
                    ));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('Geçersiz kilo değeri. Lütfen bir sayı girin.'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              child: Text('Kaydet', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchPrograms() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen giriş yapın.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
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

      await _fetchNextProgram(uid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Veri çekme hatası: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _fetchNextProgram(String uid) async {
    DocumentSnapshot lastProgramSnapshot = await FirebaseFirestore.instance
        .collection('Users/$uid/Values')
        .doc('LastProgram')
        .get();

    if (!lastProgramSnapshot.exists) {
      lastProgramName = 'Program Yok';
      nextProgramName = 'Program Yok';
      return;
    }

    String? lastProgramId = lastProgramSnapshot['programId'];
    DocumentSnapshot lastProgramDoc = await FirebaseFirestore.instance
        .collection('Users/$uid/Programs')
        .doc(lastProgramId)
        .get();

    lastProgramName =
        lastProgramDoc.exists ? lastProgramDoc['programAdi'] : 'Program Yok';

    // Programları sıralayın
    programs.sort((a, b) =>
        (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp));

    // Son yapılan programın indeksini bul
    int lastProgramIndex =
        programs.indexWhere((program) => program['programId'] == lastProgramId);

    if (lastProgramIndex != -1) {
      // Son program son eleman ise, sıradaki program listenin başındaki program
      if (lastProgramIndex == programs.length - 1) {
        nextProgramName = programs[0]['programAdi'];
      } else {
        nextProgramName = programs[lastProgramIndex + 1]['programAdi'];
      }
    } else {
      nextProgramName = 'Program Yok';
    }

    setState(() {});
  }
}
