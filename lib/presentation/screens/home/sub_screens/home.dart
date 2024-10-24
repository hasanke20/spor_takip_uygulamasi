import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? selectedItem;
  List<Map<String, String>> items = []; // program adı ve id'yi tutacak
  String? uid;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black, // Arka plan rengini siyah yap
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users/$uid/Programs')
              .orderBy('timestamp', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                  child: Text('Program yok.',
                      style: TextStyle(color: Colors.white)));
            }

            return Column();
          },
        ),
        floatingActionButton: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 250,
                height: 150,
                child: Card(
                  color: Colors.grey[800], // Kart rengini koyu gri yap
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hemen Spor Yapmaya Başla!',
                        style: TextStyle(
                            fontSize: 24,
                            color: Colors.white), // Yazı rengini beyaz yap
                      ),
                      SizedBox(height: 20),
                      DropdownButton<String>(
                        hint: Text('Bir seçenek seçin',
                            style: TextStyle(color: Colors.white)),
                        value: selectedItem,
                        isExpanded: true,
                        dropdownColor:
                            Colors.grey[800], // Açılır menü arka plan rengi
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedItem = newValue;
                          });
                          if (newValue != null) {
                            final selectedProgram = items.firstWhere(
                                (item) => item['programAdi'] == newValue);
                            // _navigateToExerciseScreen(selectedProgram['programId']);
                          }
                        },
                        items: items.map<DropdownMenuItem<String>>(
                            (Map<String, String> value) {
                          return DropdownMenuItem<String>(
                            value: value['programAdi'],
                            child: Text(value['programAdi']!,
                                style: TextStyle(
                                    color: Colors
                                        .white)), // Yazı rengini beyaz yap
                          );
                        }).toList(),
                      ),
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

  Future<void> _fetchPrograms() async {
    if (uid != null) {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users/$uid/Programs')
          .orderBy('timestamp', descending: false)
          .get();

      setState(() {
        items = snapshot.docs.map((doc) {
          return {
            'programAdi': doc['programAdi'] as String,
            'programId': doc.id
          };
        }).toList();
      });
    }
  }

  /*void _navigateToExerciseScreen(String? programId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExerciseScreen(programId: programId), // programId'yi geçir
      ),
    );
  }*/

  @override
  void initState() {
    super.initState();

    uid = FirebaseAuth.instance.currentUser?.uid;
    _fetchPrograms();
  }
}
