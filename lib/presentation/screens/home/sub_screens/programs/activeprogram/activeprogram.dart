import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ActiveProgram extends StatefulWidget {
  final String programId;

  const ActiveProgram({Key? key, required this.programId}) : super(key: key);

  @override
  _ActiveProgramState createState() => _ActiveProgramState();
}

class _ActiveProgramState extends State<ActiveProgram> {
  int currentIndex = 0;
  List<DocumentSnapshot> exercises = [];

  void getExercises() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    String programId = widget.programId;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Users/$uid/Programs/$programId/Exercises')
        .orderBy('timestamp') // Tarihe göre sıralama
        .get();
    setState(() {
      exercises = snapshot.docs.toList(); // Tarihe göre sıralama yapıldı
    });
  }

  @override
  void initState() {
    super.initState();
    getExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        leadingWidth: 80,
        leading: Container(
          margin: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Çıkış',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        title: Text(
          'Aktif Program',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: exercises.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${currentIndex + 1}/${exercises.length}',
                    style: TextStyle(fontSize: 30, color: Colors.white),
                  ),
                  Container(
                    width: 250,
                    child: Card(
                      color: Colors.grey[850],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              exercises[currentIndex]['hareketAdi'],
                              style:
                                  TextStyle(fontSize: 24, color: Colors.white),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Set: ${exercises[currentIndex]['set']}',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                            Text(
                              'Tekrar: ${exercises[currentIndex]['tekrar']}',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                            Text(
                              'Ağırlık: ${exercises[currentIndex]['agirlik']}',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 100),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        margin: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: TextButton(
                          onPressed: currentIndex == 0
                              ? null
                              : () {
                                  setState(() {
                                    currentIndex--;
                                  });
                                },
                          child: Text(
                            'Geri',
                            style: TextStyle(
                              color: currentIndex == 0
                                  ? Colors.grey[600]
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: TextButton(
                          onPressed: currentIndex == exercises.length - 1
                              ? null
                              : () {
                                  setState(() {
                                    currentIndex++;
                                  });
                                },
                          child: Text(
                            'İleri',
                            style: TextStyle(
                              color: currentIndex == exercises.length - 1
                                  ? Colors.grey[600]
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (currentIndex == exercises.length - 1)
                    Container(
                      margin: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Programı Bitir',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
