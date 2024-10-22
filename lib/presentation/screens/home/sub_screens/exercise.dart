import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  final TextEditingController _hareketController = TextEditingController();
  final TextEditingController _setController = TextEditingController();
  final TextEditingController _tekrarController = TextEditingController();
  final TextEditingController _agirlikController = TextEditingController();

  String? uid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> addProgramToFirebase(String uid) async {
    // Program ekleme işlemleri
  }

  void clearTextFields() {
    _hareketController.clear();
    _setController.clear();
    _tekrarController.clear();
    _agirlikController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users/$uid/Programs')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Bir hata oluştu!'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final programData = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: programData.length,
                    itemBuilder: (context, index) {
                      var program = programData[index];
                      return Card(
                        margin: EdgeInsets.all(10),
                        elevation: 5,
                        child: ExpansionTile(
                          title: Text('Program: ${program.id}'),
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection(
                                      'Users/$uid/Programs/${program.id}/Exercises')
                                  .snapshots(),
                              builder: (context, exerciseSnapshot) {
                                if (exerciseSnapshot.hasError) {
                                  return Center(
                                      child: Text('Bir hata oluştu!'));
                                }

                                if (exerciseSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }

                                final exerciseData =
                                    exerciseSnapshot.data!.docs;

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: exerciseData.length,
                                  itemBuilder: (context, exerciseIndex) {
                                    var exercise = exerciseData[exerciseIndex];
                                    return Card(
                                      margin: EdgeInsets.all(5),
                                      child: ListTile(
                                        title: Text(
                                            'Hareket: ${exercise['hareketAdi']}'),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Set: ${exercise['set']}'),
                                            Text(
                                                'Tekrar: ${exercise['tekrar']}'),
                                            Text(
                                                'Ağırlık: ${exercise['agirlik']}'),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Card(
              margin: EdgeInsets.all(20),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        // Program ekleme dialogu açma
                      },
                      child: Text('Program Ekle+'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
